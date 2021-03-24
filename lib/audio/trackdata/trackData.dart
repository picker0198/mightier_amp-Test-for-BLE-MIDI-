// (c) 2020-2021 Dian Iliev (Tuntorius)
// This code is licensed under MIT license (see LICENSE.md for details)

import 'dart:convert';
import 'dart:io';
import 'package:mighty_plug_manager/audio/models/jamTrack.dart';
import 'package:mighty_plug_manager/audio/models/setlist.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class TrackData {
  static final TrackData _storage = TrackData._();
  static const tracksFile = "tracks.json";
  static const setlistsFile = "setlists.json";

  final Uuid uuid = Uuid();

  factory TrackData() {
    return _storage;
  }

  String tracksPath = "";
  String setlistsPath = "";
  late Directory? storageDirectory;
  late File _tracksFile, _setlistsFile;

  List<JamTrack> _tracksData = <JamTrack>[];
  List<JamTrack> get tracks => _tracksData;

  List<Setlist> _setlistsData = <Setlist>[];
  Setlist _allTracks = Setlist("All Tracks", []);
  List<Setlist> get setlists => [_allTracks] + _setlistsData;

  bool _tracksReady = false;

  TrackData._() {
    _init();
  }

  _init() async {
    _tracksData = <JamTrack>[];
    await _getDirectory();
    await _loadTracks();
  }

  _getDirectory() async {
    if (Platform.isAndroid) {
      storageDirectory = await getExternalStorageDirectory();
    } else if (Platform.isIOS) {
      storageDirectory = await getApplicationDocumentsDirectory();
    }
    tracksPath = path.join(storageDirectory?.path ?? "", tracksFile);
    setlistsPath = path.join(storageDirectory?.path ?? "", setlistsFile);
    _tracksFile = File(tracksPath);
    _setlistsFile = File(setlistsPath);
  }

  _loadTracks() async {
    try {
      var exists = await _tracksFile.exists();
      if (exists) {
        var _tracksJson = await _tracksFile.readAsString();
        var data = json.decode(_tracksJson);
        _tracksData =
            data.map<JamTrack>((json) => JamTrack.fromJson(json)).toList();

        //read setlists
        exists = await _setlistsFile.exists();
        if (exists) {
          var _setlistsJson = await _setlistsFile.readAsString();
          data = json.decode(_setlistsJson);

          _setlistsData = data
              .map<Setlist>((json) => Setlist.fromJson(json))
              .toList<Setlist>();
        }
        _createAllTracksSetlist();
      }
      _tracksReady = true;
    } catch (e) {
      print(e);
      //still ready
      _tracksReady = true;
      //   //no file
      //   print("Presets file not available");
    }
  }

  _createAllTracksSetlist() {
    for (int i = 0; i < _tracksData.length; i++)
      _allTracks.addTrack(_tracksData[i]);
  }

  Future waitLoading() async {
    for (int i = 0; i < 20; i++) {
      if (_tracksReady) break;
      await Future.delayed(Duration(milliseconds: 200));
    }
  }

  addTrack(String file, String name) {
    _tracksData.add(JamTrack(name: name, path: file, uuid: _generateUuid()));
    saveTracks();
  }

  JamTrack? findByUuid(String uuid) {
    for (int i = 0; i < _tracksData.length; i++)
      if (_tracksData[i].uuid == uuid) return _tracksData[i];

    return null;
  }

  removeTrack(JamTrack track) async {
    if (_tracksData.contains(track)) {
      _tracksData.remove(track);
      await saveTracks();
    }
  }

  saveTracks() async {
    String _json = json.encode(_tracksData);
    await _tracksFile.writeAsString(_json);
  }

  addSetlist(String name) {
    var setlist = Setlist(name, []);
    _setlistsData.add(setlist);
    saveSetlists();
  }

  saveSetlists() async {
    String _json = json.encode(_setlistsData);
    await _setlistsFile.writeAsString(_json);
  }

  String _generateUuid() {
    String id = "";
    bool unique = true;
    do {
      id = uuid.v4();
      // check unique
      _tracksData.forEach((element) {
        if (element.uuid == id) unique = false;
      });
    } while (unique == false);
    return id;
  }
}
