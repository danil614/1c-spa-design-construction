&НаСервере
Процедура ПриЧтенииНаСервере(ТекущийОбъект)
	ДвоичныеДанные = ТекущийОбъект.Файл.Получить();

	Если ЗначениеЗаполнено(ДвоичныеДанные) Тогда
		АдресФайла = ПоместитьВоВременноеХранилище(ДвоичныеДанные, УникальныйИдентификатор);
	Иначе
		АдресФайла = Неопределено;
	КонецЕсли;
КонецПроцедуры

&НаСервере
Процедура ПередЗаписьюНаСервере(Отказ, ТекущийОбъект, ПараметрыЗаписи)
	Если ЭтоАдресВременногоХранилища(АдресФайла) Тогда
		ДвоичныеДанные = ПолучитьИзВременногоХранилища(АдресФайла);
		ТекущийОбъект.Файл = Новый ХранилищеЗначения(ДвоичныеДанные);
	КонецЕсли;
КонецПроцедуры

&НаКлиенте
Процедура ПриОткрытии(Отказ)
	Если Не ЗначениеЗаполнено(АдресФайла) Тогда
		Элементы.СкачатьФайл.Доступность = Ложь;
	КонецЕсли;
КонецПроцедуры

&НаКлиенте
Асинх Процедура ЗагрузитьФайл(Команда)
	Если ЗначениеЗаполнено(АдресФайла) Тогда
		ТекстВопроса = "При загрузке файла старый файл будет очищен! Продолжить?";
		Ответ = Ждать ВопросАсинх(ТекстВопроса, РежимДиалогаВопрос.ДаНет);

		Если Ответ = КодВозвратаДиалога.Нет Тогда
			Возврат;
		КонецЕсли;
	КонецЕсли;

	ПараметрыПомещения = Новый ПараметрыДиалогаПомещенияФайлов;
	ПараметрыПомещения.Фильтр = "Изображение|*.png;*.jpg;*.jpeg |Текстовый документ|*.docx;*.doc |Табличный документ|*.xlsx;*.xls";

	Результат = Ждать ПоместитьФайлНаСерверАсинх(,,, ПараметрыПомещения, УникальныйИдентификатор);

	Если Результат = Неопределено Тогда
		Возврат;
	КонецЕсли;

	Если Результат.ПомещениеФайлаОтменено Тогда
		Возврат;
	КонецЕсли;

	АдресФайла = Результат.Адрес;
	Объект.ИмяФайла = Результат.СсылкаНаФайл.Имя;
	Элементы.СкачатьФайл.Доступность = Истина;
КонецПроцедуры

&НаКлиенте
Асинх Процедура СкачатьФайл(Команда)
	Если ЗначениеЗаполнено(АдресФайла) Тогда
		ПараметрыПолучения = Новый ПараметрыДиалогаПолученияФайлов;
		ПолучитьФайлССервераАсинх(АдресФайла, Объект.ИмяФайла, ПараметрыПолучения);
	КонецЕсли;
КонецПроцедуры