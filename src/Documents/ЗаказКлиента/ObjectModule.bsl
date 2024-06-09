#Если Сервер Или ТолстыйКлиентОбычноеПриложение Или ВнешнееСоединение Тогда

#Область ОбработчикиСобытий

Процедура ОбработкаЗаполнения(ДанныеЗаполнения, СтандартнаяОбработка)
	// Берем ссылку опроса клиента в заказ клиента
	Если ТипЗнч(ДанныеЗаполнения) = Тип("ДокументСсылка.ОпросКлиента") Тогда
		ОпросКлиента = ДанныеЗаполнения;
	КонецЕсли;
КонецПроцедуры

Процедура ОбработкаПроведения(Отказ, РежимПроведения)
	ОбновитьИсториюИзмененияСтатусовЗаказа();
	ОбновитьИсториюИзмененияСтатусовЭтапов();
КонецПроцедуры

Процедура ОбработкаПроверкиЗаполнения(Отказ, ПроверяемыеРеквизиты)
	ПроверитьДатыЭтапов(Отказ);
	ПроверитьНомерЭтапаВСпискеМатериалов(Отказ);
КонецПроцедуры

Процедура ПередЗаписью(Отказ, РежимЗаписи, РежимПроведения)
	Если ОбменДанными.Загрузка Тогда
		Возврат;
	КонецЕсли;
	РассчитатьСуммуЗаказа();
КонецПроцедуры

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

Процедура РассчитатьСуммуЗаказа() Экспорт
	// Сначала рассчитаем сумму материалов
	РассчитатьСуммуМатериалов();
	
	// Далее рассчитаем стоимость всех этапов
	РассчитатьСуммуЭтапов();

	СуммаЗаказа = СписокЭтапов.Итог("СтоимостьЭтапа");
КонецПроцедуры

Процедура РассчитатьСуммуМатериалов() Экспорт
	РасчетСуммыВызовСервера.РассчитатьСуммуПоЦенеИКоличеству(СписокМатериалов, "Цена", "Количество", "Сумма");
КонецПроцедуры

Процедура РассчитатьСуммуЭтапов()
	РасчетСуммыВызовСервера.РассчитатьСтоимостьЭтаповВЗаказеКлиента(ЭтотОбъект);
КонецПроцедуры

Процедура ПроверитьНомерЭтапаВСпискеМатериалов(Отказ)
	// 1. Выбираем список этапов
	// 2. Выбираем список материалов
	// 3. Соединяем этапы и материалы, получаем строки материалов, к которым не прикреплен этап
	Запрос = Новый Запрос;
	Запрос.Текст =
	"ВЫБРАТЬ
	|	СписокЭтапов.НомерСтроки
	|ПОМЕСТИТЬ ВТ_СписокЭтапов
	|ИЗ
	|	&СписокЭтапов КАК СписокЭтапов
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|ВЫБРАТЬ
	|	СписокМатериалов.НомерСтроки,
	|	СписокМатериалов.Материал,
	|	СписокМатериалов.НомерЭтапа
	|ПОМЕСТИТЬ ВТ_СписокМатериалов
	|ИЗ
	|	&СписокМатериалов КАК СписокМатериалов
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|ВЫБРАТЬ
	|	ВТ_СписокМатериалов.НомерСтроки,
	|	ВТ_СписокМатериалов.Материал,
	|	ВТ_СписокМатериалов.НомерЭтапа
	|ИЗ
	|	ВТ_СписокМатериалов КАК ВТ_СписокМатериалов
	|		ЛЕВОЕ СОЕДИНЕНИЕ ВТ_СписокЭтапов КАК ВТ_СписокЭтапов
	|		ПО ВТ_СписокМатериалов.НомерЭтапа = ВТ_СписокЭтапов.НомерСтроки
	|ГДЕ
	|	ВТ_СписокЭтапов.НомерСтроки ЕСТЬ NULL
	|
	|УПОРЯДОЧИТЬ ПО
	|	ВТ_СписокМатериалов.НомерСтроки";

	Запрос.УстановитьПараметр("СписокЭтапов", СписокЭтапов);
	Запрос.УстановитьПараметр("СписокМатериалов", СписокМатериалов);

	РезультатЗапроса = Запрос.Выполнить();
	Выборка = РезультатЗапроса.Выбрать();

	Пока Выборка.Следующий() Цикл
		Сообщение = Новый СообщениеПользователю;
		Сообщение.Текст = СтрШаблон("Материал №%1 ""%2"" имеет несуществующий №%3 этапа", Выборка.НомерСтроки,
			Выборка.Материал, Выборка.НомерЭтапа);
		Сообщение.Поле = СтрШаблон("СписокМатериалов[%1].НомерЭтапа", Выборка.НомерСтроки - 1);
		Сообщение.УстановитьДанные(ЭтотОбъект);
		Сообщение.Сообщить();

		Отказ = Истина;
	КонецЦикла;
КонецПроцедуры

Процедура ПроверитьДатыЭтапов(Отказ)
	// Проверяем, что в списке этапов дата начала меньше даты конца
	Для Каждого Этап Из СписокЭтапов Цикл
		Если Этап.ДатаНачала > Этап.ДатаОкончания Тогда
			Сообщение = Новый СообщениеПользователю;
			Сообщение.Текст = СтрШаблон("Этап №%1 с услугой ""%2"" имеет дату начала больше, чем дата окончания",
				Этап.НомерСтроки, Этап.Услуга);
			Сообщение.Поле = СтрШаблон("СписокЭтапов[%1].ДатаНачала", Этап.НомерСтроки - 1);
			Сообщение.УстановитьДанные(ЭтотОбъект);
			Сообщение.Сообщить();

			Отказ = Истина;
		КонецЕсли;
	КонецЦикла;
КонецПроцедуры

Процедура ОбновитьИсториюИзмененияСтатусовЗаказа()
	Запрос = Новый Запрос;
	Запрос.Текст =
	"ВЫБРАТЬ ПЕРВЫЕ 1
	|	ИсторияСтатусовЗаказовСрезПоследних.Заказ,
	|	ИсторияСтатусовЗаказовСрезПоследних.СтатусЗаказа,
	|	ИсторияСтатусовЗаказовСрезПоследних.Ответственный
	|ИЗ
	|	РегистрСведений.ИсторияСтатусовЗаказов.СрезПоследних КАК ИсторияСтатусовЗаказовСрезПоследних
	|ГДЕ
	|	ИсторияСтатусовЗаказовСрезПоследних.Заказ = &Заказ
	|	И ИсторияСтатусовЗаказовСрезПоследних.СтатусЗаказа = &СтатусЗаказа
	|	И ИсторияСтатусовЗаказовСрезПоследних.Ответственный = &Ответственный";

	Запрос.УстановитьПараметр("СтатусЗаказа", СтатусЗаказа);
	Запрос.УстановитьПараметр("Заказ", Ссылка);
	Запрос.УстановитьПараметр("Ответственный", Ответственный);

	РезультатЗапроса = Запрос.Выполнить();
	
	// Если нет такой записи в регистре, то добавляем
	Если РезультатЗапроса.Пустой() Тогда
		НоваяЗапись = РегистрыСведений.ИсторияСтатусовЗаказов.СоздатьМенеджерЗаписи();
		НоваяЗапись.Период = ТекущаяДатаСеанса();
		НоваяЗапись.Заказ = Ссылка;
		НоваяЗапись.СтатусЗаказа = СтатусЗаказа;
		НоваяЗапись.Ответственный = Ответственный;
		НоваяЗапись.Записать(Истина);
	КонецЕсли;
КонецПроцедуры

Процедура ОбновитьИсториюИзмененияСтатусовЭтапов()
	// Выбираем такие статусы этапов из регистра, которые отличаются от документа
	Запрос = Новый Запрос;
	Запрос.Текст =
	"ВЫБРАТЬ
	|	ЗаказКлиентаСписокЭтапов.Ссылка КАК Ссылка,
	|	ЗаказКлиентаСписокЭтапов.СтатусЭтапа КАК СтатусЭтапа,
	|	ЗаказКлиентаСписокЭтапов.НомерСтроки КАК НомерЭтапа,
	|	ЗаказКлиентаСписокЭтапов.Услуга КАК Услуга,
	|	ЗаказКлиентаСписокЭтапов.Ссылка.Ответственный КАК Ответственный
	|ПОМЕСТИТЬ ВТ_СписокЭтапов
	|ИЗ
	|	Документ.ЗаказКлиента.СписокЭтапов КАК ЗаказКлиентаСписокЭтапов
	|ГДЕ
	|	ЗаказКлиентаСписокЭтапов.Ссылка = &Заказ
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|ВЫБРАТЬ
	|	ИсторияСтатусовЭтаповСрезПоследних.Заказ КАК Заказ,
	|	ВТ_СписокЭтапов.СтатусЭтапа КАК СтатусЭтапа,
	|	ВТ_СписокЭтапов.НомерЭтапа КАК НомерЭтапа,
	|	ВТ_СписокЭтапов.Услуга КАК Услуга,
	|	ИсторияСтатусовЭтаповСрезПоследних.Ответственный КАК Ответственный
	|ИЗ
	|	ВТ_СписокЭтапов КАК ВТ_СписокЭтапов
	|		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.ИсторияСтатусовЭтапов.СрезПоследних КАК ИсторияСтатусовЭтаповСрезПоследних
	|		ПО (ИсторияСтатусовЭтаповСрезПоследних.Заказ = ВТ_СписокЭтапов.Ссылка)
	|		И (ИсторияСтатусовЭтаповСрезПоследних.СтатусЭтапа = ВТ_СписокЭтапов.СтатусЭтапа)
	|		И (ИсторияСтатусовЭтаповСрезПоследних.НомерЭтапа = ВТ_СписокЭтапов.НомерЭтапа)
	|		И (ИсторияСтатусовЭтаповСрезПоследних.Услуга = ВТ_СписокЭтапов.Услуга)
	|		И (ИсторияСтатусовЭтаповСрезПоследних.Ответственный = ВТ_СписокЭтапов.Ответственный)
	|ГДЕ
	|	ИсторияСтатусовЭтаповСрезПоследних.Заказ ЕСТЬ NULL
	|	И ИсторияСтатусовЭтаповСрезПоследних.Ответственный ЕСТЬ NULL";

	Запрос.УстановитьПараметр("Заказ", Ссылка);
	Запрос.УстановитьПараметр("Ответственный", Ответственный);
	РезультатЗапроса = Запрос.Выполнить();

	Выборка = РезультатЗапроса.Выбрать();

	НачатьТранзакцию();
	Попытка
		Пока Выборка.Следующий() Цикл
			НоваяЗапись = РегистрыСведений.ИсторияСтатусовЭтапов.СоздатьМенеджерЗаписи();
			НоваяЗапись.Период = ТекущаяДатаСеанса();
			НоваяЗапись.Заказ = Ссылка;
			НоваяЗапись.НомерЭтапа = Выборка.НомерЭтапа;
			НоваяЗапись.Услуга = Выборка.Услуга;

			НоваяЗапись.СтатусЭтапа = Выборка.СтатусЭтапа;
			НоваяЗапись.Ответственный = Ответственный;

			НоваяЗапись.Записать(Истина);
		КонецЦикла;

		ЗафиксироватьТранзакцию();
	Исключение
		Если ТранзакцияАктивна() Тогда
			ОтменитьТранзакцию();
		КонецЕсли;

		Сообщение = Новый СообщениеПользователю;
		Сообщение.Текст = "Ошибка проведения документа. Неудачная попытка изменения истории этапов";
		Сообщение.Сообщить();

		ВызватьИсключение;
	КонецПопытки;
КонецПроцедуры

#КонецОбласти

#Иначе
	ВызватьИсключение НСтр("ru = 'Недопустимый вызов объекта на клиенте.'");
#КонецЕсли