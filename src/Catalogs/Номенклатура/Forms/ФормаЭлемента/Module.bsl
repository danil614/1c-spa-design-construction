&НаКлиенте
Процедура ВидНоменклатурыПриИзменении(Элемент)
	УстановитьВидимостьСпискаМатериалов();
КонецПроцедуры

&НаКлиенте
Процедура ПриОткрытии(Отказ)
	УстановитьВидимостьСпискаМатериалов();
КонецПроцедуры

&НаКлиенте
Процедура УстановитьВидимостьСпискаМатериалов()
	Элементы.Материалы.Видимость = (Объект.ВидНоменклатуры = ПредопределенноеЗначение(
		"Перечисление.ВидНоменклатуры.Услуга"));
КонецПроцедуры