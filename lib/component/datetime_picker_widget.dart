import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:table_calendar/table_calendar.dart';

import '../consts/base.dart';
import '../generated/l10n.dart';
import '../util/router_util.dart';

class DatetimePickerWidget extends StatefulWidget {
  final DateTime? dateTime;

  final bool showDate;

  final bool showHour;

  const DatetimePickerWidget({
    super.key,
    this.dateTime,
    required this.showDate,
    required this.showHour,
  });

  static Future<DateTime?> show(
    BuildContext context, {
    DateTime? dateTime,
    bool showDate = true,
    bool showHour = true,
  }) async {
    return await showDialog(
      context: context,
      useRootNavigator: false,
      builder: (context) {
        return DatetimePickerWidget(
          dateTime: dateTime,
          showDate: showDate,
          showHour: showHour,
        );
      },
    );
  }

  @override
  State<StatefulWidget> createState() {
    return _DatetimePickerWidgetState();
  }
}

class _DatetimePickerWidgetState extends State<DatetimePickerWidget> {
  final FocusScopeNode _focusScopeNode = FocusScopeNode();

  int hour = 12;

  int minute = 0;

  DateTime _selectedDay = DateTime.now();

  DateTime _currentDay = DateTime.now();

  @override
  void initState() {
    super.initState();

    if (widget.dateTime != null) {
      _selectedDay = widget.dateTime!;
      hour = widget.dateTime!.hour;
      minute = widget.dateTime!.minute;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final cardColor = themeData.cardColor;
    final mainColor = themeData.primaryColor;
    final bigTextSize = themeData.textTheme.bodyLarge!.fontSize;
    final localization = S.of(context);

    final now = DateTime.now();
    final calendarFirstDay = now.add(const Duration(days: -3650));
    final calendarLastDay = now.add(const Duration(days: 3650));

    final titleDateFormat = DateFormat("MMM yyyy");

    final datePicker = Container(
      margin: const EdgeInsets.only(
        bottom: Base.basePadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(
              top: Base.basePadding,
              bottom: Base.basePadding + Base.basePaddingHalf,
            ),
            child: Text(
              titleDateFormat.format(_currentDay),
              style: TextStyle(
                fontSize: bigTextSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TableCalendar(
            firstDay: calendarFirstDay,
            lastDay: calendarLastDay,
            focusedDay: _selectedDay,
            headerVisible: false,
            selectedDayPredicate: (d) {
              return isSameDay(d, _selectedDay);
            },
            calendarStyle: CalendarStyle(
              rangeHighlightColor: mainColor,
              selectedDecoration: BoxDecoration(
                color: mainColor.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(
                fontSize: 16.0,
              ),
              todayDecoration: const BoxDecoration(
                color: null,
              ),
            ),
            onDaySelected: (DateTime selectedDay, DateTime focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
              });
            },
            onPageChanged: (dateTime) {
              setState(() {
                _currentDay = dateTime;
                _selectedDay = dateTime;
              });
            },
            startingDayOfWeek: StartingDayOfWeek.monday,
          ),
        ],
      ),
    );

    final timeTitleTextStyle = TextStyle(
      fontSize: bigTextSize,
      fontWeight: FontWeight.bold,
    );
    final timePicker = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        buildNumberPicker(localization.Hour, 0, 23, hour, (value) {
          setState(() {
            hour = value;
          });
        }, timeTitleTextStyle),
        Text(
          ":",
          style: timeTitleTextStyle,
        ),
        buildNumberPicker(localization.Minute, 0, 59, minute, (value) {
          setState(() {
            minute = value;
          });
        }, timeTitleTextStyle),
      ],
    );

    List<Widget> mainList = [
      // datePicker,
      // timePicker,
    ];
    if (widget.showDate) {
      mainList.add(datePicker);
    }
    if (widget.showHour) {
      mainList.add(timePicker);
    }

    mainList.add(InkWell(
      onTap: confirm,
      child: Container(
        height: 40,
        color: mainColor,
        child: Center(
          child: Text(
            localization.Confirm,
            style: TextStyle(
              color: Colors.white,
              fontSize: bigTextSize,
            ),
          ),
        ),
      ),
    ));

    final main = Container(
      color: cardColor,
      padding: const EdgeInsets.all(Base.basePadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: mainList,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.2),
      body: FocusScope(
        // Overlay 中 textField autoFocus 需要包一层 FocusScope
        node: _focusScopeNode,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: cancelFunc,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () {},
              child: main,
            ),
          ),
        ),
      ),
    );
  }

  void cancelFunc() {
    RouterUtil.back(context);
  }

  Widget buildNumberPicker(String title, int min, int max, int value,
      Function(int) onChange, TextStyle textStyle) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: textStyle,
          ),
          NumberPicker(
            itemCount: 1,
            minValue: min,
            maxValue: max,
            value: value,
            onChanged: onChange,
          )
        ],
      ),
    );
  }

  void confirm() {
    var dateTime = DateTime(
        _selectedDay.year, _selectedDay.month, _selectedDay.day, hour, minute);
    RouterUtil.back(context, dateTime);
  }
}
