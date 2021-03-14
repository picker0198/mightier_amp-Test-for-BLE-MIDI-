// (c) 2020-2021 Dian Iliev (Tuntorius)
// This code is licensed under MIT license (see LICENSE.md for details)

import 'package:flutter/material.dart';
import '../widgets/scrollParent.dart';
import '../../bluetooth/devices/presets/presetsStorage.dart';

class ChangeCategoryDialog {
  static final _formKey = GlobalKey<FormState>();
  final categoryCtrl = TextEditingController();
  final parentScroll = ScrollController();
  String category;
  String name;
  Function(String) onCategoryChange;

  ChangeCategoryDialog(
      {@required this.category, @required this.name, this.onCategoryChange}) {
    categoryCtrl.text = category;
  }

  Widget buildDialog(BuildContext context) {
    List<String> categories = PresetsStorage().getCategories();

    final _height = MediaQuery.of(context).size.height * 0.25;
    final node = FocusScope.of(context);

    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Text('Change Preset Category'),
          content: Container(
            width: double.maxFinite,
            child: SingleChildScrollView(
              reverse: true,
              controller: parentScroll,
              child: Form(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                key: _formKey,
                child: Column(
                  //mainAxisSize: MainAxisSize.max,
                  //crossAxisAlignment: CrossAxisAlignment.start,
                  //reverse: true,
                  children: [
                    Text("Categories",
                        style: TextStyle(color: Theme.of(context).hintColor)),
                    SizedBox(
                      height: 10,
                    ),
                    Container(
                      height: _height,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]),
                      ),
                      child: ScrollParent(
                        controller: parentScroll,
                        child: ListTileTheme(
                          textColor: Colors.black,
                          child: ListView.builder(
                            physics: ClampingScrollPhysics(),
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(categories[index]),
                                onTap: () {
                                  setState(() {
                                    categoryCtrl.text = categories[index];
                                  });
                                },
                              );
                            },
                            itemCount: categories.length,
                          ),
                        ),
                      ),
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: "Category"),
                      controller: categoryCtrl,
                      style: TextStyle(color: Colors.black),
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Please enter preset category';
                        }
                        if (PresetsStorage().findPreset(name, value) != null)
                          return 'The category already contains a preset with this name!';
                        return null;
                      },
                      onEditingComplete: () => node.unfocus(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel",
                  style: TextStyle(color: Theme.of(context).primaryColor)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              onPressed: () {
                if (_formKey.currentState.validate()) {
                  //call change success
                  onCategoryChange(categoryCtrl.value.text);
                  Navigator.of(context).pop();
                }
              },
              child: Text('Change'),
            ),
          ],
        );
      },
    );
  }
}
