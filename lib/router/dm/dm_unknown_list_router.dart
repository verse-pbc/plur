import 'package:flutter/material.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:provider/provider.dart';

import '../../provider/dm_provider.dart';
import 'dm_session_list_item_component.dart';

class DMUnknownListRouter extends StatefulWidget {
  DMUnknownListRouter();

  @override
  State<StatefulWidget> createState() {
    return _DMUnknownListRouter();
  }
}

class _DMUnknownListRouter extends State<DMUnknownListRouter> {
  @override
  Widget build(BuildContext context) {
    var _dmProvider = Provider.of<DMProvider>(context);
    var details = _dmProvider.unknownList;

    return Container(
      child: ListView.builder(
        itemBuilder: (context, index) {
          if (index >= details.length) {
            return null;
          }

          var detail = details[index];
          return DMSessionListItemComponent(
            detail: detail,
          );
        },
        itemCount: details.length,
      ),
    );
  }
}
