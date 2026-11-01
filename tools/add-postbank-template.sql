-- قالب «ساختار پست بانک» (بدون کمیته‌ها) را به این دیتابیس اضافه می‌کند: مجمع عمومی، هیأت مدیره، مدیریت عامل،
-- واحدهای ستادی، ۶ معاونت، ۴ مدیریت امور با اداره‌های کل، مدیریت شعب، سمت‌ها و پست‌های هر گره.
-- فقط در همین دیتابیس است (در خود محصول نیست). اگر قالبی با همین کد از قبل باشد، متنش با این نسخه عوض می‌شود
-- (شرکت‌هایی که پیش‌تر از آن ساخته‌اید تغییری نمی‌کنند). اجرای دوباره بی‌خطر است.
-- بعد از اجرا: «ساختار سازمانی» ← «افزودن شرکت» ← از قالب «ساختار پست بانک». Restart لازم نیست.
--   sqlcmd -S <server> -d TMPB -I -f 65001 -i add-postbank-template.sql
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

-- The template text, in short pieces (sqlcmd cuts lines longer than about 4 KB).
DECLARE @content nvarchar(max) = N'';
SET @content += N'{"schemaVersion":1,"key":"postbank","name":"ساختار پست بانک","description":"ساختار پست بانک ایران: مجمع عمومی، هیأت مدیره، مدیرعامل، واحدهای ستادی، معاونت‌ها و مدیریت‌های امور با اداره‌های کل و مدیریت شعب (بدون کمیته‌ها).","uiLevel":"advanced","nodeTypes":[{"key":"general-assembly","name":"مجمع عموم';
SET @content += N'ی","color":"#475569","icon":"landmark","isDomainBoundary":true},{"key":"board","name":"هیأت مدیره","color":"#1e3a8a","icon":"users","isDomainBoundary":true},{"key":"ceo-office","name":"مدیریت عامل","color":"#b45309","icon":"crown","isDomainBoundary":true},{"key":"staff-unit","name":"واحد ستادی","col';
SET @content += N'or":"#4d7c0f","icon":"building","isDomainBoundary":true},{"key":"deputy","name":"معاونت","color":"#0f766e","icon":"building-2","isDomainBoundary":true},{"key":"affairs-management","name":"مدیریت امور","color":"#0369a1","icon":"briefcase","isDomainBoundary":true},{"key":"general-department","name":"ا';
SET @content += N'داره کل","color":"#2563eb","icon":"folder-tree","isDomainBoundary":false},{"key":"office","name":"اداره","color":"#64748b","icon":"folder","isDomainBoundary":false},{"key":"branch-management","name":"مدیریت شعب استان / منطقه","color":"#be123c","icon":"map-pin","isDomainBoundary":true},{"key":"branch';
SET @content += N'","name":"شعبه","color":"#c2410c","icon":"store","isDomainBoundary":false}],"rules":[{"parent":null,"child":"general-assembly"},{"parent":"general-assembly","child":"board"},{"parent":"board","child":"ceo-office"},{"parent":"ceo-office","child":"staff-unit"},{"parent":"ceo-office","child":"deputy"},';
SET @content += N'{"parent":"ceo-office","child":"affairs-management"},{"parent":"ceo-office","child":"branch-management"},{"parent":"staff-unit","child":"office"},{"parent":"deputy","child":"general-department"},{"parent":"affairs-management","child":"general-department"},{"parent":"affairs-management","child":"bran';
SET @content += N'ch"},{"parent":"general-department","child":"office"},{"parent":"branch-management","child":"branch"}],"linkTypes":[{"key":"oversight","name":"نظارت تخصصی","lineStyle":"dotted","countsAsManager":false}],"autoLinkRules":[],"positions":[{"key":"ceo","title":"مدیرعامل","parent":null},{"key":"deputy-ceo';
SET @content += N'","title":"قائم‌مقام مدیرعامل","parent":"ceo"},{"key":"vp","title":"معاون","parent":"ceo"},{"key":"affairs-manager","title":"مدیر امور","parent":"ceo"},{"key":"general-manager","title":"مدیر کل","parent":"vp"},{"key":"branch-region-manager","title":"مدیر شعب استان / منطقه","parent":"vp"},{"key":"off';
SET @content += N'ice-head","title":"رئیس اداره","parent":"general-manager"},{"key":"expert","title":"کارشناس","parent":"office-head"},{"key":"branch-head","title":"رئیس شعبه","parent":"branch-region-manager"},{"key":"branch-deputy","title":"معاون شعبه","parent":"branch-head"},{"key":"branch-staff","title":"کارمند شع';
SET @content += N'به","parent":"branch-deputy"}],"postTemplates":[{"nodeType":"ceo-office","posts":[{"position":"ceo","isManagerPost":true,"isCompanyHead":true},{"position":"deputy-ceo"}]},{"nodeType":"staff-unit","posts":[{"position":"general-manager","isManagerPost":true},{"position":"expert"}]},{"nodeType":"deputy';
SET @content += N'","posts":[{"position":"vp","isManagerPost":true}]},{"nodeType":"affairs-management","posts":[{"position":"affairs-manager","isManagerPost":true}]},{"nodeType":"general-department","posts":[{"position":"general-manager","isManagerPost":true},{"position":"expert"}]},{"nodeType":"office","posts":[{"po';
SET @content += N'sition":"office-head","isManagerPost":true},{"position":"expert"}]},{"nodeType":"branch-management","posts":[{"position":"branch-region-manager","isManagerPost":true}]},{"nodeType":"branch","posts":[{"position":"branch-head","isManagerPost":true},{"position":"branch-deputy"},{"position":"branch-staf';
SET @content += N'f"}]}],"companyPosts":[],"nodes":[{"key":"general-assembly","name":"مجمع عمومی","type":"general-assembly","children":[{"key":"board","name":"هیأت مدیره","type":"board","children":[{"key":"ceo-office","name":"مدیریت عامل","type":"ceo-office","children":[{"key":"internal-audit","name":"اداره کل حسابرس';
SET @content += N'ی داخلی","type":"staff-unit"},{"key":"management-office","name":"اداره کل حوزه مدیریت","type":"staff-unit"},{"key":"public-relations","name":"اداره کل روابط عمومی","type":"staff-unit"},{"key":"legal","name":"اداره کل حقوقی","type":"staff-unit"},{"key":"risk-management","name":"اداره کل مدیریت ریسک",';
SET @content += N'"type":"staff-unit"},{"key":"compliance","name":"اداره کل رعایت قوانین و مقررات (تطبیق)","type":"staff-unit"},{"key":"selection-core","name":"هسته گزینش","type":"staff-unit"},{"key":"anti-money-laundering","name":"اداره کل مبارزه با پولشویی و تأمین مالی تروریسم","type":"staff-unit"},{"key":"credit-i';
SET @content += N'nternational","name":"معاونت اعتباری و بین‌الملل","type":"deputy","children":[{"key":"credits","name":"اداره کل اعتبارات","type":"general-department"},{"key":"project-review","name":"اداره کل بررسی و نظارت بر طرح‌ها","type":"general-department"},{"key":"international-affairs","name":"اداره کل امور ب';
SET @content += N'ین‌الملل","type":"general-department"},{"key":"claims-collection","name":"اداره کل پیگیری وصول مطالبات","type":"general-department"},{"key":"innovative-financing","name":"اداره کل تأمین مالی طرح‌های نوآورانه","type":"general-department"}]},{"key":"information-technology","name":"معاونت فناوری اطلاعا';
SET @content += N'ت","type":"deputy","children":[{"key":"software-systems","name":"اداره کل تأمین و نظارت بر سامانه‌های نرم‌افزاری","type":"general-department"},{"key":"electronic-banking","name":"اداره کل توسعه بانکداری الکترونیک","type":"general-department"},{"key":"security-infrastructure","name":"اداره کل امنیت و';
SET @content += N' زیرساخت","type":"general-department"}]},{"key":"finance-investment","name":"معاونت مالی و سرمایه‌گذاری","type":"deputy","children":[{"key":"accounting-shares","name":"اداره کل حسابداری و امور سهام","type":"general-department"},{"key":"treasury-payments","name":"اداره کل خزانه‌داری و نظام‌های پرداخت';
SET @content += N'","type":"general-department"},{"key":"statistics-budget","name":"اداره کل آمار و بودجه","type":"general-department"}]},{"key":"provinces-regions","name":"مدیریت امور استان‌ها و مناطق","type":"affairs-management","children":[{"key":"branch-affairs","name":"اداره کل امور شعب","type":"general-departme';
SET @content += N'nt"},{"key":"rural-counters","name":"اداره کل امور باجه‌های بانکی روستایی","type":"general-department"},{"key":"digital-branch","name":"شعبه مستقل متمرکز (دیجیتال)","type":"branch"}]},{"key":"corporate-banking","name":"مدیریت امور بانکداری شرکتی و بازاریابی","type":"affairs-management","children":[{';
SET @content += N'"key":"corporate-customers","name":"اداره کل بانکداری شرکتی و امور مشتریان حقوقی","type":"general-department"},{"key":"retail-marketing","name":"اداره کل بازاریابی و امور مشتریان حقیقی","type":"general-department"}]},{"key":"inspection","name":"مدیریت امور بازرسی، نظارت و صیانت از مشتریان","type":"a';
SET @content += N'ffairs-management","children":[{"key":"inspection-supervision","name":"اداره کل بازرسی و نظارت","type":"general-department"},{"key":"customer-protection","name":"اداره کل صیانت از مشتریان و سلامت اداری","type":"general-department"}]},{"key":"protection","name":"مدیریت امور حراست","type":"affairs-man';
SET @content += N'agement","children":[{"key":"personnel-protection","name":"اداره کل حفاظت پرسنلی","type":"general-department"},{"key":"it-documents-protection","name":"اداره کل حفاظت فناوری اطلاعات و اسناد","type":"general-department"},{"key":"physical-protection","name":"اداره کل حفاظت فیزیکی","type":"general-depa';
SET @content += N'rtment"}]},{"key":"organization-planning","name":"معاونت سازمان و برنامه‌ریزی","type":"deputy","children":[{"key":"organization-methods","name":"اداره کل سازمان و بهبود روش‌ها","type":"general-department"},{"key":"planning-monitoring","name":"اداره کل برنامه‌ریزی، کنترل برنامه‌ها و پایش عملکرد واحده';
SET @content += N'ا","type":"general-department"}]},{"key":"human-capital","name":"معاونت توسعه سرمایه انسانی و پشتیبانی","type":"deputy","children":[{"key":"human-capital-welfare","name":"اداره کل سرمایه انسانی و رفاه","type":"general-department"},{"key":"training-research","name":"اداره کل آموزش و تحقیقات","type":"';
SET @content += N'general-department"},{"key":"support-properties","name":"اداره کل پشتیبانی و املاک","type":"general-department"}]},{"key":"branch-management","name":"مدیریت شعب استان / منطقه","type":"branch-management"}]}]}]}],"links":[{"source":"internal-audit","target":"board","type":"oversight"}]}';
IF ISJSON(@content) = 0 THROW 50000, N'متن قالب خراب است؛ فایل را دوباره بگیرید.', 1;

UPDATE [org_structure].[StructureTemplates]
   SET [Content] = @content, [Name] = N'ساختار پست بانک', [ModifiedAtUtc] = SYSDATETIMEOFFSET()
 WHERE [Code] = N'postbank' AND [IsSystem] = 0;
DECLARE @updated int = @@ROWCOUNT;

INSERT INTO [org_structure].[StructureTemplates] ([Id], [TenantId], [Code], [Name], [Description], [IsSystem], [Content], [CreatedAtUtc])
SELECT NEWID(), t.[Id], N'postbank', N'ساختار پست بانک',
       N'ساختار پست بانک ایران: مجمع عمومی، هیأت مدیره، مدیرعامل، واحدهای ستادی، معاونت‌ها و مدیریت‌های امور با اداره‌های کل و مدیریت شعب (بدون کمیته‌ها).',
       0, @content, SYSDATETIMEOFFSET()
FROM [identity].[Tenants] t
WHERE NOT EXISTS (SELECT 1 FROM [org_structure].[StructureTemplates] s WHERE s.[TenantId] = t.[Id] AND s.[Code] = N'postbank');

PRINT N'قالب «ساختار پست بانک» آماده است: ' + CAST(@@ROWCOUNT AS nvarchar(10)) + N' ردیف تازه، ' + CAST(@updated AS nvarchar(10)) + N' به‌روز شد.';
GO
