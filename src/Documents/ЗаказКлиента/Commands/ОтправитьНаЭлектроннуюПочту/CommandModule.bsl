&НаКлиенте
Асинх Процедура ОбработкаКоманды(ПараметрКоманды, ПараметрыВыполненияКоманды)
	ТекстВопроса = "Отправить документы по заказу на электронную почту клиента?";
	Ответ = Ждать ВопросАсинх(ТекстВопроса, РежимДиалогаВопрос.ДаНет);

	Если Ответ = КодВозвратаДиалога.Нет Тогда
		Возврат;
	КонецЕсли;

	Договор = Новый ТабличныйДокумент;
	ПечатьДоговора(Договор, ПараметрКоманды);

	КоммерческоеПредложение = Новый ТабличныйДокумент;
	ПечатьКоммерческогоПредложения(КоммерческоеПредложение, ПараметрКоманды);

	ОтправитьПисьмо(Договор, КоммерческоеПредложение, ПараметрКоманды);
КонецПроцедуры

&НаСервере
Процедура ПечатьДоговора(ТабДок, ПараметрКоманды)
	Документы.ЗаказКлиента.ПечатьДоговора(ТабДок, ПараметрКоманды);
КонецПроцедуры

&НаСервере
Процедура ПечатьКоммерческогоПредложения(ТабДок, ПараметрКоманды)
	Документы.ЗаказКлиента.ПечатьКоммерческогоПредложения(ТабДок, ПараметрКоманды);
КонецПроцедуры

&НаСервере
Процедура ОтправитьПисьмо(Договор, КоммерческоеПредложение, Ссылка)
	Клиент = ПолучитьДанныеКлиента(Ссылка);

	Если Не ЗначениеЗаполнено(Клиент) Или Не ЗначениеЗаполнено(Клиент.ФИО) Или Не ЗначениеЗаполнено(Клиент.Почта) Тогда
		Сообщение = Новый СообщениеПользователю;
		Сообщение.Текст = СтрШаблон("Данные клиента не заполнены!");
		Сообщение.Сообщить();
		Возврат;
	КонецЕсли;

	Получатель = Клиент.Почта;

	ТемаПисьма = "Коммерческое предложение на строительство спа-комплекса";
	ТекстПисьма = СтрШаблон(
	"%1 %2,
	|
	|Предлагаем Вам услуги по строительству спа-комплекса. В приложении к данному письму прилагаются следующие документы:
	|
	|1.	Договор на выполнение работ
	|2.	Коммерческое предложение
	|
	|С уважением,
	|Генеральный директор ООО ""СПАСтрой""
	|%3", Клиент.Обращение, Клиент.ФИО, Константы.ГенеральныйДиректорКомпании.Получить());

	ОписаниеОшибки = Неопределено;

	ВложениеДоговор = ОтправкаНаЭлектроннуюПочтуВызовСервера.ПолучитьВложениеПоТабличномуДокументу(Договор,
		"Договор.docx", ТипФайлаТабличногоДокумента.DOCX);
	ВложениеКоммерческоеПредложение = ОтправкаНаЭлектроннуюПочтуВызовСервера.ПолучитьВложениеПоТабличномуДокументу(
		КоммерческоеПредложение, "КоммерческоеПредложение.docx", ТипФайлаТабличногоДокумента.DOCX);

	Вложения = Новый Массив;
	Вложения.Добавить(ВложениеДоговор);
	Вложения.Добавить(ВложениеКоммерческоеПредложение);

	УчетнаяЗапись = Справочники.УчетныеЗаписиЭлектроннойПочты.СистемнаяУчетнаяЗапись;
	Отправлено = ОтправкаНаЭлектроннуюПочтуВызовСервера.ОтправитьПисьмо(УчетнаяЗапись, Получатель, ТемаПисьма,
		ТекстПисьма, ОписаниеОшибки, Вложения);

	Сообщение = Новый СообщениеПользователю;
	Если Отправлено Тогда
		Сообщение.Текст = СтрШаблон("Письмо отправлено!");
	Иначе
		Сообщение.Текст = СтрШаблон("Ошибка отправки: %1", ОписаниеОшибки);
	КонецЕсли;

	Сообщение.Сообщить();
КонецПроцедуры

&НаСервере
Функция ПолучитьДанныеКлиента(Ссылка)
	Запрос = Новый Запрос;
	Запрос.Текст =
	"ВЫБРАТЬ
	|	КлиентыКонтактнаяИнформация.Представление КАК Представление,
	|	КлиентыКонтактнаяИнформация.Ссылка КАК Ссылка
	|ПОМЕСТИТЬ ВТ_ПочтаКлиент
	|ИЗ
	|	Справочник.Клиенты.КонтактнаяИнформация КАК КлиентыКонтактнаяИнформация
	|ГДЕ
	|	КлиентыКонтактнаяИнформация.Вид = ЗНАЧЕНИЕ(Перечисление.ВидКонтактнойИнформации.АдресЭлектроннойПочты)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|ВЫБРАТЬ
	|	ЗаказКлиента.ОпросКлиента.Клиент КАК ФИО,
	|	ВЫБОР
	|		КОГДА ЗаказКлиента.ОпросКлиента.Клиент.Пол = Значение(Перечисление.Пол.Мужской)
	|			ТОГДА ""Уважаемый""
	|		ИНАЧЕ ""Уважаемая""
	|	КОНЕЦ КАК Обращение,
	|	ВТ_ПочтаКлиент.Представление КАК Почта
	|ИЗ
	|	Документ.ЗаказКлиента КАК ЗаказКлиента
	|		ЛЕВОЕ СОЕДИНЕНИЕ ВТ_ПочтаКлиент КАК ВТ_ПочтаКлиент
	|		ПО ЗаказКлиента.ОпросКлиента.Клиент = ВТ_ПочтаКлиент.Ссылка
	|ГДЕ
	|	ЗаказКлиента.Ссылка В (&Ссылка)";
	Запрос.Параметры.Вставить("Ссылка", Ссылка);

	Выборка = Запрос.Выполнить().Выбрать();

	Если Выборка.Следующий() Тогда
		Возврат Выборка;
	Иначе
		Возврат Неопределено;
	КонецЕсли;
КонецФункции