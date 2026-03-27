import 'package:flutter/widgets.dart';

import '../layout/responsive.dart';

Widget desktopContent(BuildContext context, Widget child,
    {double maxWidth = 900}) {
  return desktopWrap(context, child, maxWidth: maxWidth);
}
