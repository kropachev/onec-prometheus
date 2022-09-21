﻿#Если Сервер Или ТолстыйКлиентОбычноеПриложение Или ВнешнееСоединение Тогда

#Область ПрограммныйИнтерфейс

// Возвращает структуру с примером заполнения настройки выгрузки по типу метрики
Функция ПримерЗаполнения(ТипМетрики) Экспорт

	Если ТипМетрики = Перечисления.Prometheus_ТипыМертик.Histogram Тогда
		Возврат ПримерЗаполненияГистограмма();
	Иначе
		Возврат Неопределено;
	КонецЕсли; 
	
КонецФункции

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

// Возвращает структуру с примером заполнения настройки выгрузки с типом Гистограмма
Функция ПримерЗаполненияГистограмма()

	СтруктураНастроек = Новый Структура;
	СтруктураНастроек.Вставить("Наименование", "APDEX ключевых операций");
	СтруктураНастроек.Вставить("ТипМетрики", Перечисления.Prometheus_ТипыМертик.Histogram);
	СтруктураНастроек.Вставить("МетрикаИмя", "onec_key_operation_apdex_score");
	СтруктураНастроек.Вставить("МетрикаКомментарий", "APDEX по ключевым операциям");
	СтруктураНастроек.Вставить("СпособСбора", Перечисления.Prometheus_СпособыСбораМерик.Запрос);
	
	МассивТЧЗначенияПараметров = Новый Массив;
	СтруктураПараметра = Новый Структура;
	СтруктураПараметра.Вставить("ИмяПараметра", "ГраницаЗавершенияСбора");
	СтруктураПараметра.Вставить("ЗначениеПараметра", "ЗначениеПараметра = СтруктураНастроек.ГраницаЗавершенияСбора;");
	СтруктураПараметра.Вставить("Вычисляемый", Истина);
	СтруктураПараметра.Вставить("Используется", Истина);
	МассивТЧЗначенияПараметров.Добавить(СтруктураПараметра);
	
	СтруктураПараметра = Новый Структура;
	СтруктураПараметра.Вставить("ИмяПараметра", "ДатаПоследнейВыгрузки");
	СтруктураПараметра.Вставить("ЗначениеПараметра", "ЗначениеПараметра = ГраницаСбораМетрикUTC(НастройкаВыгрузки);
	|Если Не ЗначениеЗаполнено(ЗначениеПараметра) Тогда
	|    // Если дата последней выгрузки не установлена, 
	|    // то по умолчанию выгружаем замеры за одну минуту.
	|    ЗначениеПараметра = СтруктураНастроек.ГраницаЗавершенияСбора - 60;
	|КонецЕсли;");
	СтруктураПараметра.Вставить("Вычисляемый", Истина);
	СтруктураПараметра.Вставить("Используется", Истина);
	МассивТЧЗначенияПараметров.Добавить(СтруктураПараметра);
	
	СтруктураНастроек.Вставить("МассивТЧЗначенияПараметров", МассивТЧЗначенияПараметров);
	
	ТекстЗапроса = "ВЫБРАТЬ
	|	Замеры.ДатаНачалаЗамера КАК ДатаНачалаЗамера,
	|	КлючевыеОперации.Приоритет КАК Приоритет,
	|	КлючевыеОперации.Ссылка КАК КлючеваяОперация,
	|	КлючевыеОперации.Наименование КАК КлючеваяОперацияСтрока,
	|	КОЛИЧЕСТВО(*) КАК КоличествоЗамеров,
	|	СУММА(Замеры.ВремяВыполнения) КАК ЗамерыСумма,
	|	СУММА(ВЫБОР
	|			КОГДА Замеры.ВремяВыполнения <= КлючевыеОперации.ЦелевоеВремя
	|				ТОГДА 1
	|			ИНАЧЕ 0
	|		КОНЕЦ) КАК N_T,
	|	СУММА(ВЫБОР
	|			КОГДА Замеры.ВремяВыполнения > КлючевыеОперации.ЦелевоеВремя
	|					И Замеры.ВремяВыполнения <= 4 * КлючевыеОперации.ЦелевоеВремя
	|				ТОГДА 1
	|			ИНАЧЕ 0
	|		КОНЕЦ) КАК N_T_4T,
	|	СУММА(ВЫБОР
	|			КОГДА Замеры.ВремяВыполнения > 4 * КлючевыеОперации.ЦелевоеВремя
	|				ТОГДА 1
	|			ИНАЧЕ 0
	|		КОНЕЦ) КАК N_4T,
	|	КлючевыеОперации.ЦелевоеВремя КАК ЦелевоеВремя,
	|	МИНИМУМ(Замеры.ВремяВыполнения) КАК МинимальноеЗначение,
	|	МАКСИМУМ(Замеры.ВремяВыполнения) КАК МаксимальноеЗначение
	|ПОМЕСТИТЬ ЗамерыТекущие
	|ИЗ
	|	РегистрСведений.ЗамерыВремени КАК Замеры
	|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ Справочник.КлючевыеОперации КАК КлючевыеОперации
	|		ПО Замеры.КлючеваяОперация = КлючевыеОперации.Ссылка
	|ГДЕ
	|	Замеры.ДатаЗаписи > &ДатаПоследнейВыгрузки
	|	И Замеры.ДатаЗаписи <= &ГраницаЗавершенияСбора
	
	|СГРУППИРОВАТЬ ПО
	|	КлючевыеОперации.Ссылка,
	|	КлючевыеОперации.Приоритет,
	|	КлючевыеОперации.ЦелевоеВремя,
	|	Замеры.ДатаНачалаЗамера
	|;
	
	|////////////////////////////////////////////////////////////////////////////////
	|ВЫБРАТЬ
	|	ЗамерыТекущие.КлючеваяОперация КАК КлючеваяОперация,
	|	ЗамерыТекущие.КлючеваяОперацияСтрока КАК КлючеваяОперацияСтрока,
	|	ЗамерыТекущие.КоличествоЗамеров КАК КоличествоЗамеров,
	|	ЗамерыТекущие.ЗамерыСумма КАК ЗамерыСумма,
	|	ЗамерыТекущие.N_T КАК N_T,
	|	ЗамерыТекущие.N_T_4T КАК N_T_4T,
	|	ЗамерыТекущие.N_4T КАК N_4T,
	|	ЗамерыТекущие.ЦелевоеВремя КАК ЦелевоеВремя,
	|	ЗамерыТекущие.МинимальноеЗначение КАК МинимальноеЗначение,
	|	ЗамерыТекущие.МаксимальноеЗначение КАК МаксимальноеЗначение,
	|	ВЫРАЗИТЬ((СУММА(ЗамерыТекущие.N_T) + СУММА(ЗамерыТекущие.N_T_4T / 2)) / СУММА(ЗамерыТекущие.КоличествоЗамеров) КАК ЧИСЛО(4, 3)) КАК APDEX
	|ИЗ
	|	ЗамерыТекущие КАК ЗамерыТекущие
	
	|СГРУППИРОВАТЬ ПО
	|	ЗамерыТекущие.КлючеваяОперация,
	|	ЗамерыТекущие.КоличествоЗамеров,
	|	ЗамерыТекущие.ЗамерыСумма,
	|	ЗамерыТекущие.N_T,
	|	ЗамерыТекущие.N_T_4T,
	|	ЗамерыТекущие.N_4T,
	|	ЗамерыТекущие.ЦелевоеВремя,
	|	ЗамерыТекущие.МинимальноеЗначение,
	|	ЗамерыТекущие.МаксимальноеЗначение,
	|	ЗамерыТекущие.КлючеваяОперацияСтрока
	|ИТОГИ
	|	МАКСИМУМ(КлючеваяОперацияСтрока),
	|	СУММА(КоличествоЗамеров),
	|	СУММА(ЗамерыСумма),
	|	СУММА(N_T),
	|	СУММА(N_T_4T),
	|	СУММА(N_4T),
	|	МАКСИМУМ(ЦелевоеВремя),
	|	МАКСИМУМ(МинимальноеЗначение),
	|	МИНИМУМ(МаксимальноеЗначение),
	|	ВЫРАЗИТЬ((СУММА(N_T) + СУММА(N_T_4T / 2)) / СУММА(КоличествоЗамеров) КАК ЧИСЛО(4, 3)) КАК APDEX
	|ПО
	|	КлючеваяОперация";
	
	СтруктураНастроек.Вставить("ТекстЗапроса", ТекстЗапроса);
	
	Возврат СтруктураНастроек;
	
КонецФункции

#КонецОбласти

#КонецЕсли
