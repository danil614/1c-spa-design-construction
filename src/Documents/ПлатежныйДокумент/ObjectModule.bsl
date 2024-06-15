Процедура ОбработкаПроведения(Отказ, Режим)
	// Обнуляем движения
	Движения.ДенежныеСредства.Записывать = Истина;
	Движения.Записать();

	// Проверяем сумму оплаты
	Запрос = Новый Запрос;
	Запрос.Текст =
	"ВЫБРАТЬ
	|	ЕСТЬNULL(ДенежныеСредстваОстатки.СуммаОстаток, 0) КАК СуммаОплачено,
	|	ЕСТЬNULL(ДокументЗаказКлиента.СуммаЗаказа, 0) КАК СуммаЗаказа
	|ИЗ
	|	РегистрНакопления.ДенежныеСредства.Остатки(&Период, ЗаказКлиента = &Ссылка) КАК ДенежныеСредстваОстатки,
	|	Документ.ЗаказКлиента КАК ДокументЗаказКлиента
	|ГДЕ
	|	ДокументЗаказКлиента.Ссылка = &Ссылка";

	Запрос.УстановитьПараметр("Ссылка", ЗаказКлиента);
	Запрос.УстановитьПараметр("Период", МоментВремени());

	РезультатЗапроса = Запрос.Выполнить();
	Выборка = РезультатЗапроса.Выбрать();

	Если Выборка.Следующий() Тогда
		СуммаОплачено = Выборка.СуммаОплачено;
		СуммаЗаказа = Выборка.СуммаЗаказа;
	Иначе
		СуммаОплачено = 0;
		СуммаЗаказа = 0;
	КонецЕсли;

	Если СуммаОплаты + СуммаОплачено > СуммаЗаказа Тогда
		Сообщение = Новый СообщениеПользователю;
		Сообщение.Текст = СтрШаблон(
				"Сумма оплаты заказа (%1 ₽) и оплаченная сумма (%2 ₽) больше суммы заказа (%3 ₽)", СуммаОплаты,
			СуммаОплачено, СуммаЗаказа);
		Сообщение.Поле = "СуммаОплаты";
		Сообщение.УстановитьДанные(ЭтотОбъект);
		Сообщение.Сообщить();

		Отказ = Истина;
		Возврат;
	КонецЕсли;

	// Регистр ДенежныеСредства
	Движения.ДенежныеСредства.Записывать = Истина;

	Движение = Движения.ДенежныеСредства.Добавить();
	Движение.Период = Дата;
	Движение.ВидДвижения = ВидДвиженияНакопления.Приход;
	Движение.ЗаказКлиента = ЗаказКлиента;
	Движение.Сумма = СуммаОплаты;
КонецПроцедуры