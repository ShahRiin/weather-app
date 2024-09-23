import 'package:intl/intl.dart';
import 'package:weather_app/units/constans.dart';


String getFormattedDateTime(num dt ,{String pattern='MMM dd , hh:mm a'}){
  return DateFormat(pattern).format(DateTime.fromMillisecondsSinceEpoch(dt.toInt()*1000));
}

String getIconUrl (String icon)=> '$iconUrlPrefix$icon$iconUrlSuffix';