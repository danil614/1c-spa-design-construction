Процедура ОбработкаПроведения(Отказ, Режим)
	// Регистр ЦеныНоменклатуры
	Движения.ЦеныНоменклатуры.Записывать = Истина;
	Для Каждого ТекСтрокаСписокНоменклатуры Из СписокНоменклатуры Цикл
		Движение = Движения.ЦеныНоменклатуры.Добавить();
		Движение.Период = Дата;
		Движение.Номенклатура = ТекСтрокаСписокНоменклатуры.Номенклатура;
		Движение.Цена = ТекСтрокаСписокНоменклатуры.Цена;
	КонецЦикла;
КонецПроцедуры