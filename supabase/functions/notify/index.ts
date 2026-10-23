// Loqta notification dispatcher.
//
// Runs server-side only. It is invoked by a Database Webhook on the tables that
// represent marketplace events, writes the in-app `notifications` row, and then
// pushes the same payload to the device through Firebase Cloud Messaging.
//
// Security model
//   * The function is NOT exposed to the Flutter app. The app never calls it and
//     never holds a credential that could.
//   * It verifies the shared webhook secret (LOQTA_WEBHOOK_SECRET) so a
//     request cannot be forged from the public internet.
//   * Firebase Admin credentials come from the Supabase Vault / server-side
//     secrets (FIREBASE_SERVICE_ACCOUNT). They are never in the Flutter bundle.
//
// Install:
//   supabase secrets set \
//     FIREBASE_SERVICE_ACCOUNT='<service account JSON>' \
//     LOQTA_WEBHOOK_SECRET='<random string>'
//   supabase functions deploy notify --no-verify-jwt
//
// Then in the Dashboard: Database > Webhooks, point the INSERT hooks for
// `messages`, `reservations`, `listings` and `ratings` at this function and set
// the same LOQTA_WEBHOOK_SECRET header.
//
// This file compiles as Deno/TypeScript. The Flutter app does not depend on it.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

type NotificationType =
  | 'new_message'
  | 'reservation_requested'
  | 'reservation_accepted'
  | 'listing_status_update'
  | 'transaction_completed'
  | 'rating_received'
  | 'report_account_update'

interface EventPayload {
  type: string
  record: Record<string, any>
  // Supabase webhooks populate this for DELETE events.
  old_record?: Record<string, any> | null
}

/** Map an originating event onto one of the supported notification types. */
function resolveType(payload: EventPayload): NotificationType | null {
  const table = payload.type ?? ''
  const record = payload.record ?? {}

  if (table === 'messages') return 'new_message'
  if (table === 'reservations') {
    return record.status === 'accepted' ? 'reservation_accepted' : 'reservation_requested'
  }
  if (table === 'listings') return 'listing_status_update'
  if (table === 'ratings') return 'rating_received'
  if (table === 'reports') return 'report_account_update'
  return null
}

/**
 * Work out who should be notified.
 *
 * Returns an empty list when the event concerns the person who caused it —
 * nobody wants a push telling them about their own action.
 */
function resolveRecipient(
  payload: EventPayload,
  notificationType: NotificationType,
): { userId: string; conversationId: string | null; listingId: string | null }[] {
  const record = payload.record ?? {}

  if (notificationType === 'new_message') {
    // conversation_participants is deliberately not used: conversations carry
    // buyer_id / seller_id, so the recipient is the other participant.
    const recipients = [record.buyer_id, record.seller_id]
      .filter((id): id is string => typeof id === 'string' && id.length > 0)
      .filter((id) => id !== record.sender_id)

    return recipients.map((userId) => ({
      userId,
      conversationId: record.conversation_id ?? null,
      listingId: null,
    }))
  }

  const userId: string | undefined = record.owner_id ?? record.user_id
  if (!userId || typeof userId !== 'string') return []

  return [
    {
      userId,
      conversationId: null,
      listingId: typeof record.listing_id === 'string' ? record.listing_id : null,
    },
  ]
}

function buildCopy(
  notificationType: NotificationType,
  record: Record<string, any>,
): { title: string; body: string } {
  switch (notificationType) {
    case 'new_message':
      return {
        title: 'New message',
        body: String(record.content ?? '').slice(0, 140) || 'Sent you a message.',
      }
    case 'reservation_requested':
      return { title: 'Reservation request', body: 'A buyer requested one of your listings.' }
    case 'reservation_accepted':
      return { title: 'Reservation accepted', body: 'Your reservation was accepted.' }
    case 'listing_status_update':
      return { title: 'Listing update', body: `Your listing is now ${record.status ?? 'updated'}.` }
    case 'transaction_completed':
      return { title: 'Transaction completed', body: 'A transaction on your listing is complete.' }
    case 'rating_received':
      return { title: 'Rating received', body: 'Someone left you a rating.' }
    case 'report_account_update':
      return { title: 'Account update', body: 'There is an update on a report you submitted.' }
    default:
      return { title: 'Loqta', body: 'You have a new update.' }
  }
}

Deno.serve(async (request) => {
  // Only POST: Supabase Database Webhooks are POSTs.
  if (request.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 })
  }

  const secret = Deno.env.get('LOQTA_WEBHOOK_SECRET')
  const providedSecret = request.headers.get('x-loqta-webhook-secret')

  if (!secret || providedSecret !== secret) {
    return new Response('Unauthorized', { status: 401 })
  }

  let payload: EventPayload
  try {
    payload = await request.json()
  } catch {
    return new Response('Bad request', { status: 400 })
  }

  const notificationType = resolveType(payload)
  if (!notificationType) {
    // Unsupported event: acknowledge so Supabase does not retry forever.
    return Response.json({ skipped: 'unsupported event' })
  }

  const recipients = resolveRecipient(payload, notificationType)
  if (recipients.length === 0) {
    return Response.json({ skipped: 'no recipient' })
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  })

  const { title, body } = buildCopy(notificationType, payload.record)
  const results: unknown[] = []

  for (const recipient of recipients) {
    // de-duplicate: a webhook may fire more than once for the same event, and
    // `dedupe_key` is UNIQUE so the second insert is ignored rather than
    // producing a duplicate notification.
    const dedupeKey = [
      notificationType,
      recipient.userId,
      recipient.conversationId ?? recipient.listingId ?? payload.record?.id ?? '',
      payload.record?.id ?? '',
    ].join(':')

    const { error: insertError } = await admin.from('notifications').upsert(
      {
        user_id: recipient.userId,
        type: notificationType,
        title,
        body,
        listing_id: recipient.listingId,
        conversation_id: recipient.conversationId,
        dedupe_key: dedupeKey,
      },
      { onConflict: 'dedupe_key', ignoreDuplicates: true },
    )

    if (insertError) {
      results.push({ userId: recipient.userId, stored: false, error: insertError.message })
      continue
    }

    results.push({ userId: recipient.userId, stored: true, pushed: await push(admin, recipient.userId, {
      title,
      body,
      type: notificationType,
      conversation_id: recipient.conversationId,
      listing_id: recipient.listingId,
    }) })
  }

  return Response.json({ ok: true, results })
})

/**
 * Best-effort FCM delivery.
 *
 * Swallows its own failures: a device that is unreachable must not stop the
 * in-app record from being written, which is the source of truth.
 */
async function push(
  admin: ReturnType<typeof createClient>,
  userId: string,
  payload: Record<string, unknown>,
): Promise<string> {
  const serviceAccount = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')
  if (!serviceAccount) return 'skipped: FIREBASE_SERVICE_ACCOUNT not set'

  // device_tokens is a table owned by the client app; it stores only the FCM
  // registration token for a user's devices.
  const { data: tokens } = await admin
    .from('device_tokens')
    .select('token')
    .eq('user_id', userId)

  const list = (tokens ?? []).map((row: any) => row.token as string).filter(Boolean)
  if (list.length === 0) return 'skipped: no device tokens'

  try {
    const { getMessaging } = await import('https://esm.sh/firebase-admin@11/messaging')
    const credentials = JSON.parse(serviceAccount)
    const app = await import('https://esm.sh/firebase-admin@11/app').then((m) =>
      m.initializeApp({ credential: m.cert(credentials) }),
    )
    const messaging = getMessaging(app)

    await messaging.sendEachForMulticast({
      tokens: list,
      notification: {
        title: String(payload.title ?? 'Loqta'),
        body: String(payload.body ?? ''),
      },
      data: Object.fromEntries(
        Object.entries(payload).map(([key, value]) => [key, value == null ? '' : String(value)]),
      ),
      android: { priority: 'high' },
      apns: { headers: { 'apns-priority': '10' } },
    })

    return 'sent'
  } catch (error) {
    return `failed: ${error instanceof Error ? error.message : String(error)}`
  }
}