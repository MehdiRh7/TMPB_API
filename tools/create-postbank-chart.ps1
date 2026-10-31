<#
.SYNOPSIS
  چارت سازمانی پست بانک ایران را روی یک نصب تازه (یا هر دیتابیسی که این شرکت را ندارد) می‌سازد.

.DESCRIPTION
  فقط از API خود سامانه استفاده می‌کند (همان کارهای صفحه‌ی «ساختار سازمانی»)، پس قاعده‌های سامانه اعمال می‌شود.
  ساخته می‌شود:
  - شرکت «پست بانک ایران» با کد PB (و لوگو، اگر -LogoPath داده شود).
  - جزءهای چارت (مجمع عمومی، هیئت مدیره، کمیته، مدیرعامل، قائم‌مقام، معاونت، مدیریت، اداره کل، واحد)؛
    اگر جزئی با همین نام از قبل باشد همان استفاده می‌شود.
  - ۵۳ گره با همان نام، کد، جزء و جای چارت فعلی.
  - قاعده‌های «سلسله‌مراتب مجاز» همین چارت (به قاعده‌های موجود اضافه می‌شوند).
  - ۴ رابطه‌ی گزارش‌دهی نقطه‌چین (حسابرسی داخلی ← هیئت مدیره و کمیته حسابرسی، تطبیق ← کمیته رعایت قوانین،
    مدیریت ریسک ← کمیته مدیریت ریسک).
  ساخته نمی‌شود: کاربران، پست‌ها و انتصاب‌ها (برای کاربر آزمایشی: tools/seed-test-users.ps1 -CompanyCode PB).
  اگر شرکتی با کد PB یا همین نام از قبل باشد و گره داشته باشد، هیچ کاری نمی‌کند (دوبار ساخته نمی‌شود)؛ اگر گره نداشته باشد
  همان شرکت استفاده می‌شود. اگر وسط ساخت گره‌ها خطا بدهد، گره‌های ساخته‌شده را حذف کنید (یا reset-org-structure.sql) و دوباره اجرا کنید.

.EXAMPLE
  .\create-postbank-chart.ps1 -ApiUrl http://localhost:5000 -AdminPassword 'رمز مدیر'
.EXAMPLE
  .\create-postbank-chart.ps1 -ApiUrl https://api-host -AdminPassword '...' -LogoPath C:\logo\postbank.png
#>
param(
  [Parameter(Mandatory = $true)][string]$ApiUrl,
  [string]$AdminUser = 'admin',
  [Parameter(Mandatory = $true)][string]$AdminPassword,
  [string]$CompanyName = 'پست بانک ایران',
  [string]$CompanyCode = 'PB',
  # لوگوی شرکت (PNG، JPEG یا WebP، حداکثر ۵۱۲ کیلوبایت)؛ خالی: بدون لوگو.
  [string]$LogoPath = ''
)

$ErrorActionPreference = 'Stop'
$ApiUrl = $ApiUrl.TrimEnd('/')
$Base = '/api/org-structure'

function Invoke-Api([string]$Method, [string]$Path, $Body = $null) {
  $headers = @{ Accept = 'application/json' }
  if ($script:Token) { $headers.Authorization = "Bearer $($script:Token)" }
  $req = @{ Method = $Method; Uri = "$ApiUrl$Path"; Headers = $headers; UseBasicParsing = $true }
  if ($null -ne $Body) {
    # فارسی: بدنه همیشه UTF-8 فرستاده می‌شود (Windows PowerShell 5.1 هم).
    $req.Body = [System.Text.Encoding]::UTF8.GetBytes(($Body | ConvertTo-Json -Depth 6 -Compress))
    $req.ContentType = 'application/json; charset=utf-8'
  }
  try {
    $response = Invoke-WebRequest @req
    $text = [System.Text.Encoding]::UTF8.GetString($response.RawContentStream.ToArray())
    if ([string]::IsNullOrWhiteSpace($text)) { return $null }
    return $text | ConvertFrom-Json
  } catch {
    $detail = $_.ErrorDetails.Message
    if (-not $detail -and $_.Exception.Response) {
      try { $detail = (New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())).ReadToEnd() } catch { }
    }
    throw "$Method $Path : $($_.Exception.Message) $detail"
  }
}

# ---------------------------------------------------------------- the chart (as it is in the Post Bank test system)
$NodeTypes = @(
  @{ Name = 'مجمع عمومی'; Color = '#2563eb'; Icon = 'folder'; IsDomainBoundary = $true }
  @{ Name = 'هیئت مدیره'; Color = '#2563eb'; Icon = 'folder'; IsDomainBoundary = $true }
  @{ Name = 'کمیته'; Color = '#2563eb'; Icon = 'folder'; IsDomainBoundary = $true }
  @{ Name = 'مدیرعامل'; Color = '#2563eb'; Icon = 'folder'; IsDomainBoundary = $true }
  @{ Name = 'قائم‌مقام'; Color = '#2563eb'; Icon = 'folder'; IsDomainBoundary = $true }
  @{ Name = 'اداره کل'; Color = '#2563eb'; Icon = 'folder'; IsDomainBoundary = $false }
  @{ Name = 'واحد'; Color = '#2563eb'; Icon = 'folder'; IsDomainBoundary = $true }
  @{ Name = 'معاونت'; Color = '#2563eb'; Icon = 'folder'; IsDomainBoundary = $true }
  @{ Name = 'مدیریت'; Color = '#2563eb'; Icon = 'folder'; IsDomainBoundary = $true }
)

# کد، نام، جزء چارت و کد گره‌ی بالا (خالی: بالاترین گره‌ی شرکت). به همین ترتیب ساخته می‌شوند.
$Nodes = @(
  @{ Code = 'GA'; Name = 'مجمع عمومی'; Type = 'مجمع عمومی'; Parent = '' }
  @{ Code = 'BOD'; Name = 'هیئت مدیره'; Type = 'هیئت مدیره'; Parent = 'GA' }
  @{ Code = 'C-IT'; Name = 'کمیته عالی فناوری اطلاعات'; Type = 'کمیته'; Parent = 'BOD' }
  @{ Code = 'C-HR'; Name = 'کمیته جبران خدمات'; Type = 'کمیته'; Parent = 'BOD' }
  @{ Code = 'C-AUD'; Name = 'کمیته حسابرسی'; Type = 'کمیته'; Parent = 'BOD' }
  @{ Code = 'C-RSK'; Name = 'کمیته مدیریت ریسک'; Type = 'کمیته'; Parent = 'BOD' }
  @{ Code = 'C-CMP'; Name = 'کمیته رعایت قوانین و مقررات'; Type = 'کمیته'; Parent = 'BOD' }
  @{ Code = 'CEO'; Name = 'مدیرعامل'; Type = 'مدیرعامل'; Parent = 'BOD' }
  @{ Code = 'DEP'; Name = 'قائم‌مقام'; Type = 'قائم‌مقام'; Parent = 'CEO' }
  @{ Code = 'S-AUD'; Name = 'اداره کل حسابرسی داخلی'; Type = 'اداره کل'; Parent = 'CEO' }
  @{ Code = 'S-MGT'; Name = 'اداره کل حوزه مدیریت'; Type = 'اداره کل'; Parent = 'CEO' }
  @{ Code = 'S-PR'; Name = 'اداره کل روابط عمومی'; Type = 'اداره کل'; Parent = 'CEO' }
  @{ Code = 'S-LAW'; Name = 'اداره کل حقوقی'; Type = 'اداره کل'; Parent = 'CEO' }
  @{ Code = 'S-RSK'; Name = 'اداره کل مدیریت ریسک'; Type = 'اداره کل'; Parent = 'CEO' }
  @{ Code = 'S-CMP'; Name = 'اداره کل رعایت قوانین و مقررات (تطبیق)'; Type = 'اداره کل'; Parent = 'CEO' }
  @{ Code = 'S-AML'; Name = 'اداره کل مبارزه با پولشویی و تامین مالی تروریسم'; Type = 'اداره کل'; Parent = 'CEO' }
  @{ Code = 'S-SEL'; Name = 'هسته گزینش'; Type = 'واحد'; Parent = 'CEO' }
  @{ Code = 'BR-PRV'; Name = 'مدیریت شعب استان / منطقه'; Type = 'واحد'; Parent = 'CEO' }
  @{ Code = 'V-HR'; Name = 'معاونت توسعه سرمایه انسانی و پشتیبانی'; Type = 'معاونت'; Parent = 'CEO' }
  @{ Code = 'HR-1'; Name = 'اداره کل سرمایه انسانی و رفاه'; Type = 'اداره کل'; Parent = 'V-HR' }
  @{ Code = 'HR-2'; Name = 'اداره کل آموزش و تحقیقات'; Type = 'اداره کل'; Parent = 'V-HR' }
  @{ Code = 'HR-3'; Name = 'اداره کل پشتیبانی و املاک'; Type = 'اداره کل'; Parent = 'V-HR' }
  @{ Code = 'V-ORG'; Name = 'معاونت سازمان و برنامه‌ریزی'; Type = 'معاونت'; Parent = 'CEO' }
  @{ Code = 'ORG-1'; Name = 'اداره کل سازمان و بهبود روش‌ها'; Type = 'اداره کل'; Parent = 'V-ORG' }
  @{ Code = 'ORG-2'; Name = 'اداره کل برنامه‌ریزی، کنترل برنامه‌ها و پایش عملکرد واحدها'; Type = 'اداره کل'; Parent = 'V-ORG' }
  @{ Code = 'M-SEC'; Name = 'مدیریت امور حراست'; Type = 'مدیریت'; Parent = 'CEO' }
  @{ Code = 'SEC-1'; Name = 'اداره کل حفاظت پرسنلی'; Type = 'اداره کل'; Parent = 'M-SEC' }
  @{ Code = 'SEC-2'; Name = 'اداره کل حفاظت فناوری اطلاعات و اسناد'; Type = 'اداره کل'; Parent = 'M-SEC' }
  @{ Code = 'SEC-3'; Name = 'اداره کل حفاظت فیزیکی'; Type = 'اداره کل'; Parent = 'M-SEC' }
  @{ Code = 'M-INS'; Name = 'مدیریت امور بازرسی، نظارت و صیانت از مشتریان'; Type = 'مدیریت'; Parent = 'CEO' }
  @{ Code = 'INS-1'; Name = 'اداره کل بازرسی و نظارت'; Type = 'اداره کل'; Parent = 'M-INS' }
  @{ Code = 'INS-2'; Name = 'اداره کل صیانت از مشتریان و سلامت اداری'; Type = 'اداره کل'; Parent = 'M-INS' }
  @{ Code = 'M-CRP'; Name = 'مدیریت امور بانکداری شرکتی و بازاریابی'; Type = 'مدیریت'; Parent = 'CEO' }
  @{ Code = 'CRP-1'; Name = 'اداره کل بانکداری شرکتی و امور مشتریان حقوقی'; Type = 'اداره کل'; Parent = 'M-CRP' }
  @{ Code = 'CRP-2'; Name = 'اداره کل بازاریابی و امور مشتریان حقیقی'; Type = 'اداره کل'; Parent = 'M-CRP' }
  @{ Code = 'M-PRV'; Name = 'مدیریت امور استان‌ها و مناطق'; Type = 'مدیریت'; Parent = 'CEO' }
  @{ Code = 'PRV-1'; Name = 'اداره کل امور شعب'; Type = 'اداره کل'; Parent = 'M-PRV' }
  @{ Code = 'PRV-2'; Name = 'اداره کل امور باجه‌های بانکی روستایی'; Type = 'اداره کل'; Parent = 'M-PRV' }
  @{ Code = 'BR-DIG'; Name = 'شعبه مستقل مرکزی (دیجیتال)'; Type = 'واحد'; Parent = 'M-PRV' }
  @{ Code = 'V-FIN'; Name = 'معاونت مالی و سرمایه‌گذاری'; Type = 'معاونت'; Parent = 'CEO' }
  @{ Code = 'FIN-1'; Name = 'اداره کل حسابداری و امور سهام'; Type = 'اداره کل'; Parent = 'V-FIN' }
  @{ Code = 'FIN-2'; Name = 'اداره کل خزانه‌داری و نظام‌های پرداخت'; Type = 'اداره کل'; Parent = 'V-FIN' }
  @{ Code = 'FIN-3'; Name = 'اداره کل آمار و بودجه'; Type = 'اداره کل'; Parent = 'V-FIN' }
  @{ Code = 'V-IT'; Name = 'معاونت فناوری اطلاعات'; Type = 'معاونت'; Parent = 'CEO' }
  @{ Code = 'IT-1'; Name = 'اداره کل تامین و نظارت بر سامانه‌های نرم‌افزاری'; Type = 'اداره کل'; Parent = 'V-IT' }
  @{ Code = 'IT-2'; Name = 'اداره کل توسعه بانکداری الکترونیک'; Type = 'اداره کل'; Parent = 'V-IT' }
  @{ Code = 'IT-3'; Name = 'اداره کل امنیت و زیرساخت'; Type = 'اداره کل'; Parent = 'V-IT' }
  @{ Code = 'V-CRD'; Name = 'معاونت اعتباری و بین‌الملل'; Type = 'معاونت'; Parent = 'CEO' }
  @{ Code = 'CRD-1'; Name = 'اداره کل اعتبارات'; Type = 'اداره کل'; Parent = 'V-CRD' }
  @{ Code = 'CRD-2'; Name = 'اداره کل بررسی و نظارت بر طرح‌ها'; Type = 'اداره کل'; Parent = 'V-CRD' }
  @{ Code = 'CRD-3'; Name = 'اداره کل امور بین‌الملل'; Type = 'اداره کل'; Parent = 'V-CRD' }
  @{ Code = 'CRD-4'; Name = 'اداره کل پیگیری وصول مطالبات'; Type = 'اداره کل'; Parent = 'V-CRD' }
  @{ Code = 'CRD-5'; Name = 'اداره کل تامین مالی طرح‌های نوآورانه'; Type = 'اداره کل'; Parent = 'V-CRD' }
)

# رابطه‌های گزارش‌دهی نقطه‌چین (از گره، به گره).
$Links = @(
  @{ From = 'S-AUD'; To = 'C-AUD'; Type = 'گزارش‌دهی نقطه‌چین' }
  @{ From = 'S-AUD'; To = 'BOD'; Type = 'گزارش‌دهی نقطه‌چین' }
  @{ From = 'S-CMP'; To = 'C-CMP'; Type = 'گزارش‌دهی نقطه‌چین' }
  @{ From = 'S-RSK'; To = 'C-RSK'; Type = 'گزارش‌دهی نقطه‌چین' }
)
$LinkTypes = @(
  @{ Name = 'گزارش‌دهی نقطه‌چین'; LineStyle = 'dotted'; CountsAsManager = $false }
)

# «سلسله‌مراتب مجاز»: چه جزئی زیر چه جزئی (Parent خالی: سطح اول شرکت). به قاعده‌های موجود اضافه می‌شود.
$Rules = @(
  @{ Parent = 'مدیرعامل'; Child = 'مدیریت' }
  @{ Parent = ''; Child = 'مجمع عمومی' }
  @{ Parent = 'مدیریت'; Child = 'واحد' }
  @{ Parent = 'هیئت مدیره'; Child = 'کمیته' }
  @{ Parent = 'هیئت مدیره'; Child = 'مدیرعامل' }
  @{ Parent = 'مدیریت'; Child = 'اداره کل' }
  @{ Parent = 'مدیرعامل'; Child = 'معاونت' }
  @{ Parent = ''; Child = 'کمیته' }
  @{ Parent = 'مجمع عمومی'; Child = 'هیئت مدیره' }
  @{ Parent = 'مدیرعامل'; Child = 'واحد' }
  @{ Parent = 'معاونت'; Child = 'اداره کل' }
  @{ Parent = 'مدیرعامل'; Child = 'اداره کل' }
  @{ Parent = 'مدیرعامل'; Child = 'قائم‌مقام' }
)

# ---------------------------------------------------------------- run
if ($LogoPath -and -not (Test-Path -LiteralPath $LogoPath)) { throw "فایل لوگو پیدا نشد: $LogoPath" }

Write-Host "ورود با $AdminUser ..."
$login = Invoke-Api POST '/api/identity/auth/login' @{ identifier = $AdminUser; password = $AdminPassword }
$script:Token = $login.accessToken
if (-not $script:Token) { throw 'ورود انجام نشد (توکن برنگشت). اگر کد تصویر خواسته شد، یک بار از صفحه وارد شوید و دوباره اجرا کنید.' }

$existing = @(Invoke-Api GET "$Base/companies") | Where-Object { $_.code -eq $CompanyCode -or $_.name -eq $CompanyName } | Select-Object -First 1
if ($existing -and @(Invoke-Api GET "$Base/nodes?companyId=$($existing.id)").Count -gt 0) {
  Write-Host "شرکت «$($existing.name)» (کد $($existing.code)) از قبل هست و گره دارد؛ کاری انجام نشد." -ForegroundColor Yellow
  exit 1
}

# Chart parts: the existing one with the same name, else a new one.
$typeIds = @{}
$knownTypes = @(Invoke-Api GET "$Base/node-types")
foreach ($t in $NodeTypes) {
  $found = $knownTypes | Where-Object { $_.name -eq $t.Name } | Select-Object -First 1
  if (-not $found) {
    $found = Invoke-Api POST "$Base/node-types" @{ name = $t.Name; color = $t.Color; icon = $t.Icon; isDomainBoundary = $t.IsDomainBoundary }
    Write-Host "  جزء چارت ساخته شد: $($t.Name)"
  }
  $typeIds[$t.Name] = $found.id
}

# The rules: the existing ones, plus those the chart needs.
$current = Invoke-Api GET "$Base/node-type-rules"
$ruleList = New-Object System.Collections.ArrayList
foreach ($r in @($current.rules)) { [void]$ruleList.Add(@{ parentNodeTypeId = $r.parentNodeTypeId; childNodeTypeId = $r.childNodeTypeId }) }
$added = 0
foreach ($r in $Rules) {
  $parent = if ($r.Parent) { $typeIds[$r.Parent] } else { $null }
  $child = $typeIds[$r.Child]
  if (-not ($ruleList | Where-Object { $_.parentNodeTypeId -eq $parent -and $_.childNodeTypeId -eq $child })) {
    [void]$ruleList.Add(@{ parentNodeTypeId = $parent; childNodeTypeId = $child }); $added++
  }
}
if ($added -gt 0) {
  Invoke-Api PUT "$Base/node-type-rules" @{ rules = @($ruleList) } | Out-Null
  Write-Host "  $added قاعده‌ی «سلسله‌مراتب مجاز» اضافه شد."
}

if ($existing) {
  $company = $existing
  Write-Host "شرکت «$($company.name)» از قبل بود (بدون گره)؛ همان استفاده می‌شود."
} else {
  $company = Invoke-Api POST "$Base/companies" @{ name = $CompanyName; code = $CompanyCode }
  Write-Host "شرکت ساخته شد: $($company.name) (کد $($company.code))"
}

if ($LogoPath) {
  # multipart/form-data with the field «logo» (as the company form sends it).
  Add-Type -AssemblyName System.Net.Http
  $client = New-Object System.Net.Http.HttpClient
  $client.DefaultRequestHeaders.Authorization = New-Object System.Net.Http.Headers.AuthenticationHeaderValue('Bearer', $script:Token)
  $form = New-Object System.Net.Http.MultipartFormDataContent
  $bytes = [System.IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $LogoPath))
  $file = New-Object System.Net.Http.ByteArrayContent(,$bytes)
  $form.Add($file, 'logo', [System.IO.Path]::GetFileName($LogoPath))
  $answer = $client.PutAsync("$ApiUrl$Base/companies/$($company.id)/logo", $form).Result
  if (-not $answer.IsSuccessStatusCode) { Write-Host "لوگو ثبت نشد: $($answer.StatusCode) $($answer.Content.ReadAsStringAsync().Result)" -ForegroundColor Yellow }
  else { Write-Host 'لوگو ثبت شد.' }
}

$nodeIds = @{}
$n = 0
foreach ($node in $Nodes) {
  $body = @{ name = $node.Name; nodeTypeId = $typeIds[$node.Type]; code = $node.Code }
  if ($node.Parent) { $body.parentNodeId = $nodeIds[$node.Parent] } else { $body.companyId = $company.id; $body.parentNodeId = $null }
  $created = Invoke-Api POST "$Base/nodes" $body
  $nodeIds[$node.Code] = $created.id
  $n++
  Write-Host ("  [{0}/{1}] {2}" -f $n, $Nodes.Count, $node.Name)
}

$linkTypeIds = @{}
$knownLinkTypes = @(Invoke-Api GET "$Base/link-types")
foreach ($t in $LinkTypes) {
  $found = $knownLinkTypes | Where-Object { $_.name -eq $t.Name } | Select-Object -First 1
  if (-not $found) { $found = Invoke-Api POST "$Base/link-types" @{ name = $t.Name; lineStyle = $t.LineStyle; countsAsManager = $t.CountsAsManager } }
  $linkTypeIds[$t.Name] = $found.id
}

$made = @(Invoke-Api GET "$Base/links")
foreach ($link in $Links) {
  $from = $nodeIds[$link.From]; $to = $nodeIds[$link.To]
  # A rule may have linked them already when the node was made.
  if ($made | Where-Object { $_.fromNodeId -eq $from -and $_.toNodeId -eq $to }) { continue }
  Invoke-Api POST "$Base/links" @{ fromNodeId = $from; toNodeId = $to; linkTypeId = $linkTypeIds[$link.Type] } | Out-Null
}

$count = @(Invoke-Api GET "$Base/nodes?companyId=$($company.id)").Count
$linkCount = @(Invoke-Api GET "$Base/links" | Where-Object { $nodeIds.Values -contains $_.fromNodeId }).Count
Write-Host ""
Write-Host "تمام شد: $count گره و $linkCount رابطه در «$CompanyName»." -ForegroundColor Green
