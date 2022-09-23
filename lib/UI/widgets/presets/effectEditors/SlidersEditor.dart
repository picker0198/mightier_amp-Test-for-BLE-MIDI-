import 'package:flutter/material.dart';
import 'package:tinycolor2/tinycolor2.dart';
import 'package:undo/undo.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../../bluetooth/NuxDeviceControl.dart';
import '../../../../bluetooth/devices/NuxConstants.dart';
import '../../../../bluetooth/devices/effects/Processor.dart';
import '../../../../bluetooth/devices/presets/Preset.dart';
import '../../../../bluetooth/devices/utilities/DelayTapTimer.dart';
import '../../../../bluetooth/devices/value_formatters/TempoFormatter.dart';
import '../../../../bluetooth/devices/value_formatters/ValueFormatter.dart';
import '../../../popups/alertDialogs.dart';
import '../../ModeControl.dart';
import '../../thickSlider.dart';

class SlidersEditor extends StatefulWidget {
  final Preset preset;
  final int slot;
  const SlidersEditor({Key? key, required this.preset, required this.slot})
      : super(key: key);

  @override
  State<SlidersEditor> createState() => _SlidersEditorState();
}

class _SlidersEditorState extends State<SlidersEditor> {
  DelayTapTimer timer = DelayTapTimer();
  double _oldValue = 0;

  ThickSlider _createSlider(Parameter param, bool isPortrait) {
    bool enabled = widget.preset.slotEnabled(widget.slot);
    return ThickSlider(
      value: param.value,
      parameter: param,
      min: param.formatter.min.toDouble(),
      max: param.formatter.max.toDouble(),
      label: param.name,
      labelFormatter: (val) => param.label,
      activeColor: enabled
          ? widget.preset.effectColor(widget.slot)
          : TinyColor(widget.preset.effectColor(widget.slot))
              .desaturate(80)
              .color,
      onChanged: (val) {
        setState(() {
          widget.preset.setParameterValue(param, val);
        });
      },
      onDragStart: (val) {
        _oldValue = val;
      },
      onDragEnd: (val) {
        //undo/redo here
        NuxDeviceControl.instance().changes.add(Change<double>(
            _oldValue,
            () => widget.preset.setParameterValue(param, val),
            (oldVal) => widget.preset.setParameterValue(param, oldVal)));
        NuxDeviceControl.instance().undoStackChanged();
      },
      handleVerticalDrag: isPortrait,
    );
  }

  ModeControl _createModeControl(Parameter param) {
    bool enabled = widget.preset.slotEnabled(widget.slot);
    return ModeControl(
      value: param.value,
      parameter: param,
      onChanged: (val) {
        NuxDeviceControl.instance().changes.add(Change<double>(
            _oldValue,
            () => widget.preset.setParameterValue(param, val),
            (oldVal) => widget.preset.setParameterValue(param, oldVal)));
        NuxDeviceControl.instance().undoStackChanged();
      },
      effectColor: widget.preset.effectColor(widget.slot),
      enabled: enabled,
    );
  }

  Widget _createTapTempo(Parameter param) {
    bool enabled = widget.preset.slotEnabled(widget.slot);
    return RawMaterialButton(
      onPressed: () {
        timer.addClickTime();
        var result = timer.calculate();
        if (result != false) {
          setState(() {
            var newValue = (param.formatter as TempoFormatter)
                .timeToPercentage(result / 1000);
            widget.preset.setParameterValue(param, newValue);

            NuxDeviceControl.instance().changes.add(Change<double>(
                param.value,
                () => widget.preset.setParameterValue(param, newValue),
                (oldVal) => widget.preset.setParameterValue(param, oldVal)));
            NuxDeviceControl.instance().undoStackChanged();
          });
        }
      },
      elevation: 2.0,
      fillColor: enabled
          ? TinyColor(widget.preset.effectColor(widget.slot)).darken(15).color
          : TinyColor(widget.preset.effectColor(widget.slot))
              .desaturate(80)
              .darken(15)
              .color,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Text(
          "Tap",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
      padding: EdgeInsets.all(15.0),
      shape: CircleBorder(),
    );
  }

  Widget _createCabinetRename(Cabinet cab) {
    return Column(
      children: [
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
                onPressed: () {
                  var _dev = NuxDeviceControl.instance().device;
                  AlertDialogs.showInputDialog(context,
                      title: "Set cabinet name",
                      description: "",
                      value: cab.name, onConfirm: (value) {
                    _dev.renameCabinet(cab.nuxIndex, value);
                  });
                },
                icon: Icon(Icons.drive_file_rename_outline),
                label: Text("Rename Cabinet")),
            ElevatedButton.icon(
                onPressed: () {
                  var _dev = NuxDeviceControl.instance().device;
                  _dev.renameCabinet(cab.nuxIndex, cab.cabName);
                },
                icon: Icon(Icons.restart_alt),
                label: Text("Reset Name"))
          ],
        ),
        InkWell(
          onTap: () async {
            var _url = AppConstants.patcherUrl;
            await canLaunchUrlString(_url)
                ? await launchUrlString(_url)
                : throw 'Could not launch $_url';
          },
          child: Container(
            height: 50,
            child: Center(
              child: RichText(
                  text: TextSpan(
                style: TextStyle(fontSize: 18),
                children: [
                  TextSpan(text: "Use "),
                  TextSpan(
                    text: "NUX IR Patcher",
                    style: TextStyle(
                        color: Colors.lightBlue,
                        decoration: TextDecoration.underline),
                  ),
                  TextSpan(text: " to import custom IRs")
                ],
              )),
            ),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    var _preset = widget.preset;
    var _slot = widget.slot;
    var _dev = NuxDeviceControl.instance().device;
    var sliders = <Widget>[];

    var isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    //get all the parameters for the slot
    List<Processor> prc = _preset.getEffectsForSlot(_slot);

    //create the widgets to edit them
    var _selected = _preset.getSelectedEffectForSlot(_slot);
    List<Parameter> params = prc[_selected].parameters;

    if (params.length > 0) {
      for (int i = 0; i < params.length; i++) {
        var widget;
        switch (params[i].formatter.inputType) {
          case InputType.SliderInput:
            widget = Flexible(
                fit: FlexFit.loose,
                child: _createSlider(params[i], isPortrait));
            break;
          case InputType.SwitchInput:
            widget = _createModeControl(params[i]);
            break;
        }
        sliders.add(widget);

        //add tap tempo button
        if (params[i].formatter is TempoFormatter) {
          sliders.add(_createTapTempo(params[i]));
        }

        //add cabinet rename if supported
        if (_dev.cabinetSupport &&
            _dev.cabinetSlotIndex == _slot &&
            _dev.hackableIRs) {
          sliders.add(_createCabinetRename(prc[_selected] as Cabinet));
        }
      }
      sliders.add(const SizedBox(
        height: 20,
      ));
    }

    return Column(mainAxisSize: MainAxisSize.min, children: sliders);
  }
}