-- قالب «ساختار پست بانک» را به این دیتابیس اضافه می‌کند: مجمع عمومی، هیأت مدیره و ۵ کمیته‌ی آن (با خط نقطه‌چین)، مدیریت عامل،
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
SET @content += N'{"schemaVersion":1,"key":"postbank","name":"ساختار پست بانک","description":"ساختار پست بانک ایران: مجمع عمومی، هیأت مدیره و کمیته‌های آن با خط نقطه‌چین، مدیرعامل، واحدهای ستادی، معاونت‌ها و مدیریت‌های امور با اداره‌های کل و مدیریت شعب.","uiLevel":"advanced","nodeTypes":[{"key":"general-assembly","na';
SET @content += N'me":"مجمع عمومی","color":"#475569","icon":"landmark","isDomainBoundary":true},{"key":"board","name":"هیأت مدیره","color":"#1e3a8a","icon":"users","isDomainBoundary":true},{"key":"ceo-office","name":"مدیریت عامل","color":"#b45309","icon":"crown","isDomainBoundary":true},{"key":"staff-unit","name":"وا';
SET @content += N'حد ستادی","color":"#4d7c0f","icon":"building","isDomainBoundary":true},{"key":"deputy","name":"معاونت","color":"#0f766e","icon":"building-2","isDomainBoundary":true},{"key":"affairs-management","name":"مدیریت امور","color":"#0369a1","icon":"briefcase","isDomainBoundary":true},{"key":"general-departm';
SET @content += N'ent","name":"اداره کل","color":"#2563eb","icon":"folder-tree","isDomainBoundary":false},{"key":"office","name":"اداره","color":"#64748b","icon":"folder","isDomainBoundary":false},{"key":"branch-management","name":"مدیریت شعب استان / منطقه","color":"#be123c","icon":"map-pin","isDomainBoundary":true},';
SET @content += N'{"key":"branch","name":"شعبه","color":"#c2410c","icon":"store","isDomainBoundary":false},{"key":"committee","name":"کمیته","color":"#7c3aed","icon":"users-round","isDomainBoundary":true}],"rules":[{"parent":null,"child":"general-assembly"},{"parent":"general-assembly","child":"board"},{"parent":"boa';
SET @content += N'rd","child":"ceo-office"},{"parent":"ceo-office","child":"staff-unit"},{"parent":"ceo-office","child":"deputy"},{"parent":"ceo-office","child":"affairs-management"},{"parent":"ceo-office","child":"branch-management"},{"parent":"staff-unit","child":"office"},{"parent":"deputy","child":"general-depart';
SET @content += N'ment"},{"parent":"affairs-management","child":"general-department"},{"parent":"affairs-management","child":"branch"},{"parent":"general-department","child":"office"},{"parent":"branch-management","child":"branch"},{"parent":null,"child":"committee"}],"linkTypes":[{"key":"oversight","name":"نظارت تخص';
SET @content += N'صی","lineStyle":"dotted","countsAsManager":false},{"key":"board-committee","name":"کمیته‌ی هیأت مدیره","lineStyle":"dotted","countsAsManager":false}],"autoLinkRules":[],"positions":[{"key":"ceo","title":"مدیرعامل","parent":null},{"key":"deputy-ceo","title":"قائم‌مقام مدیرعامل","parent":"ceo"},{"key"';
SET @content += N':"vp","title":"معاون","parent":"ceo"},{"key":"affairs-manager","title":"مدیر امور","parent":"ceo"},{"key":"general-manager","title":"مدیر کل","parent":"vp"},{"key":"branch-region-manager","title":"مدیر شعب استان / منطقه","parent":"vp"},{"key":"office-head","title":"رئیس اداره","parent":"general-mana';
SET @content += N'ger"},{"key":"expert","title":"کارشناس","parent":"office-head"},{"key":"branch-head","title":"رئیس شعبه","parent":"branch-region-manager"},{"key":"branch-deputy","title":"معاون شعبه","parent":"branch-head"},{"key":"branch-staff","title":"کارمند شعبه","parent":"branch-deputy"}],"postTemplates":[{"nod';
SET @content += N'eType":"ceo-office","posts":[{"position":"ceo","isManagerPost":true,"isCompanyHead":true},{"position":"deputy-ceo"}]},{"nodeType":"staff-unit","posts":[{"position":"general-manager","isManagerPost":true},{"position":"expert"}]},{"nodeType":"deputy","posts":[{"position":"vp","isManagerPost":true}]},{';
SET @content += N'"nodeType":"affairs-management","posts":[{"position":"affairs-manager","isManagerPost":true}]},{"nodeType":"general-department","posts":[{"position":"general-manager","isManagerPost":true},{"position":"expert"}]},{"nodeType":"office","posts":[{"position":"office-head","isManagerPost":true},{"positio';
SET @content += N'n":"expert"}]},{"nodeType":"branch-management","posts":[{"position":"branch-region-manager","isManagerPost":true}]},{"nodeType":"branch","posts":[{"position":"branch-head","isManagerPost":true},{"position":"branch-deputy"},{"position":"branch-staff"}]}],"companyPosts":[],"nodes":[{"key":"general-ass';
SET @content += N'embly","name":"مجمع عمومی","type":"general-assembly","children":[{"key":"board","name":"هیأت مدیره","type":"board","children":[{"key":"ceo-office","name":"مدیریت عامل","type":"ceo-office","children":[{"key":"internal-audit","name":"اداره کل حسابرسی داخلی","type":"staff-unit"},{"key":"management-offi';
SET @content += N'ce","name":"اداره کل حوزه مدیریت","type":"staff-unit"},{"key":"public-relations","name":"اداره کل روابط عمومی","type":"staff-unit"},{"key":"legal","name":"اداره کل حقوقی","type":"staff-unit"},{"key":"risk-management","name":"اداره کل مدیریت ریسک","type":"staff-unit"},{"key":"compliance","name":"ادار';
SET @content += N'ه کل رعایت قوانین و مقررات (تطبیق)","type":"staff-unit"},{"key":"selection-core","name":"هسته گزینش","type":"staff-unit"},{"key":"anti-money-laundering","name":"اداره کل مبارزه با پولشویی و تأمین مالی تروریسم","type":"staff-unit"},{"key":"credit-international","name":"معاونت اعتباری و بین‌الملل","ty';
SET @content += N'pe":"deputy","children":[{"key":"credits","name":"اداره کل اعتبارات","type":"general-department"},{"key":"project-review","name":"اداره کل بررسی و نظارت بر طرح‌ها","type":"general-department"},{"key":"international-affairs","name":"اداره کل امور بین‌الملل","type":"general-department"},{"key":"claims';
SET @content += N'-collection","name":"اداره کل پیگیری وصول مطالبات","type":"general-department"},{"key":"innovative-financing","name":"اداره کل تأمین مالی طرح‌های نوآورانه","type":"general-department"}]},{"key":"information-technology","name":"معاونت فناوری اطلاعات","type":"deputy","children":[{"key":"software-syste';
SET @content += N'ms","name":"اداره کل تأمین و نظارت بر سامانه‌های نرم‌افزاری","type":"general-department"},{"key":"electronic-banking","name":"اداره کل توسعه بانکداری الکترونیک","type":"general-department"},{"key":"security-infrastructure","name":"اداره کل امنیت و زیرساخت","type":"general-department"}]},{"key":"fina';
SET @content += N'nce-investment","name":"معاونت مالی و سرمایه‌گذاری","type":"deputy","children":[{"key":"accounting-shares","name":"اداره کل حسابداری و امور سهام","type":"general-department"},{"key":"treasury-payments","name":"اداره کل خزانه‌داری و نظام‌های پرداخت","type":"general-department"},{"key":"statistics-bud';
SET @content += N'get","name":"اداره کل آمار و بودجه","type":"general-department"}]},{"key":"provinces-regions","name":"مدیریت امور استان‌ها و مناطق","type":"affairs-management","children":[{"key":"branch-affairs","name":"اداره کل امور شعب","type":"general-department"},{"key":"rural-counters","name":"اداره کل امور با';
SET @content += N'جه‌های بانکی روستایی","type":"general-department"},{"key":"digital-branch","name":"شعبه مستقل متمرکز (دیجیتال)","type":"branch"}]},{"key":"corporate-banking","name":"مدیریت امور بانکداری شرکتی و بازاریابی","type":"affairs-management","children":[{"key":"corporate-customers","name":"اداره کل بانکداری';
SET @content += N' شرکتی و امور مشتریان حقوقی","type":"general-department"},{"key":"retail-marketing","name":"اداره کل بازاریابی و امور مشتریان حقیقی","type":"general-department"}]},{"key":"inspection","name":"مدیریت امور بازرسی، نظارت و صیانت از مشتریان","type":"affairs-management","children":[{"key":"inspection-sup';
SET @content += N'ervision","name":"اداره کل بازرسی و نظارت","type":"general-department"},{"key":"customer-protection","name":"اداره کل صیانت از مشتریان و سلامت اداری","type":"general-department"}]},{"key":"protection","name":"مدیریت امور حراست","type":"affairs-management","children":[{"key":"personnel-protection","n';
SET @content += N'ame":"اداره کل حفاظت پرسنلی","type":"general-department"},{"key":"it-documents-protection","name":"اداره کل حفاظت فناوری اطلاعات و اسناد","type":"general-department"},{"key":"physical-protection","name":"اداره کل حفاظت فیزیکی","type":"general-department"}]},{"key":"organization-planning","name":"معا';
SET @content += N'ونت سازمان و برنامه‌ریزی","type":"deputy","children":[{"key":"organization-methods","name":"اداره کل سازمان و بهبود روش‌ها","type":"general-department"},{"key":"planning-monitoring","name":"اداره کل برنامه‌ریزی، کنترل برنامه‌ها و پایش عملکرد واحدها","type":"general-department"}]},{"key":"human-capit';
SET @content += N'al","name":"معاونت توسعه سرمایه انسانی و پشتیبانی","type":"deputy","children":[{"key":"human-capital-welfare","name":"اداره کل سرمایه انسانی و رفاه","type":"general-department"},{"key":"training-research","name":"اداره کل آموزش و تحقیقات","type":"general-department"},{"key":"support-properties","nam';
SET @content += N'e":"اداره کل پشتیبانی و املاک","type":"general-department"}]},{"key":"branch-management","name":"مدیریت شعب استان / منطقه","type":"branch-management"}]}]}]},{"key":"it-committee","name":"کمیته عالی فناوری اطلاعات","type":"committee"},{"key":"remuneration-committee","name":"کمیته جبران خدمات","type":';
SET @content += N'"committee"},{"key":"audit-committee","name":"کمیته حسابرسی","type":"committee"},{"key":"compliance-committee","name":"کمیته رعایت قوانین و مقررات","type":"committee"},{"key":"risk-committee","name":"کمیته مدیریت ریسک","type":"committee"}],"links":[{"source":"internal-audit","target":"board","type":';
SET @content += N'"oversight"},{"source":"it-committee","target":"board","type":"board-committee"},{"source":"remuneration-committee","target":"board","type":"board-committee"},{"source":"audit-committee","target":"board","type":"board-committee"},{"source":"compliance-committee","target":"board","type":"board-commit';
SET @content += N'tee"},{"source":"risk-committee","target":"board","type":"board-committee"},{"source":"internal-audit","target":"audit-committee","type":"oversight"},{"source":"risk-management","target":"risk-committee","type":"oversight"},{"source":"compliance","target":"compliance-committee","type":"oversight"}]}';
IF ISJSON(@content) = 0 THROW 50000, N'متن قالب خراب است؛ فایل را دوباره بگیرید.', 1;

UPDATE [org_structure].[StructureTemplates]
   SET [Content] = @content, [Name] = N'ساختار پست بانک', [ModifiedAtUtc] = SYSDATETIMEOFFSET()
 WHERE [Code] = N'postbank' AND [IsSystem] = 0;
DECLARE @updated int = @@ROWCOUNT;

INSERT INTO [org_structure].[StructureTemplates] ([Id], [TenantId], [Code], [Name], [Description], [IsSystem], [Content], [CreatedAtUtc])
SELECT NEWID(), t.[Id], N'postbank', N'ساختار پست بانک',
       N'ساختار پست بانک ایران: مجمع عمومی، هیأت مدیره و کمیته‌های آن با خط نقطه‌چین، مدیرعامل، واحدهای ستادی، معاونت‌ها و مدیریت‌های امور با اداره‌های کل و مدیریت شعب.',
       0, @content, SYSDATETIMEOFFSET()
FROM [identity].[Tenants] t
WHERE NOT EXISTS (SELECT 1 FROM [org_structure].[StructureTemplates] s WHERE s.[TenantId] = t.[Id] AND s.[Code] = N'postbank');

PRINT N'قالب «ساختار پست بانک» آماده است: ' + CAST(@@ROWCOUNT AS nvarchar(10)) + N' ردیف تازه، ' + CAST(@updated AS nvarchar(10)) + N' به‌روز شد.';
GO
