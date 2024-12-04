import 'package:flutter/material.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:provider/provider.dart';

import '../../provider/dm_provider.dart';
import 'dm_session_list_item_component.dart';

class DMUnknownListWidget extends StatefulWidget {
  const DMUnknownListWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _DMUnknownListWidgetState();
  }
}

class _DMUnknownListWidgetState extends State<DMUnknownListWidget> {
  @override
  Widget build(BuildContext context) {
    var _dmProvider = Provider.of<DMProvider>(context);
    var details = _dmProvider.unknownList;

    return Container(
      child: RefreshIndicator(
        child: ListView.builder(
          itemBuilder: (context, index) {
            if (index >= details.length) {
              return null;
            }

            var detail = details[index];
            return DMSessionListItemWidget(
              key: Key(
                  "${detail.dmSession.pubkey}${detail.dmSession.lastTime()}"),
              detail: detail,
            );
          },
          itemCount: details.length,
        ),
        onRefresh: () async {
          _dmProvider.query(queryAll: true);
        },
      ),
    );
  }
}
