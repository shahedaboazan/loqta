
$stringsPath = 'lib/core/localization/app_strings.dart'
$content = Get-Content -Path $stringsPath
$newContent = @()
foreach ($line in $content) {
    $newContent += $line
    if ($line -match 'String get publishListing;') {
        $newContent += '  String get preview;'
        $newContent += '  String get publish;'
        $newContent += '  String get publishSuccess;'
    }
}
Set-Content -Path $stringsPath -Value $newContent

$arPath = 'lib/core/localization/app_strings_ar.dart'
$content = Get-Content -Path $arPath
$newContent = @()
foreach ($line in $content) {
    if ($line -match 'class AppStringsAr extends AppStrings {') {
        $newContent += $line
        $newContent += '  @override'
        $newContent += '  String get preview => ''U.O1O USU+Oc'';'
        $newContent += '  @override'
        $newContent += '  String get publish => ''U+O'O'';'
        $newContent += '  @override'
        $newContent += '  String get publishSuccess => ''U.O1O U,U+O'O'';'
    } else {
        $newContent += $line
    }
}
Set-Content -Path $arPath -Value $newContent

