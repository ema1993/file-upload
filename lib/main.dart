import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(brightness: Brightness.dark),
      home: ImageCapture(),
    );
  }
}

/// Widget to capture and crop the image
class ImageCapture extends StatefulWidget {
  createState() => _ImageCaptureState();
}

class _ImageCaptureState extends State<ImageCapture> {
  /// Active image file
  File _imageFile;
  bool bandera = false;
  bool visibilidad = false;

  /// Cropper plugin
  Future<void> _cropImage() async {
    File cropped = await ImageCropper.cropImage(
      sourcePath: _imageFile.path,
      // ratioX: 1.0,
      // ratioY: 1.0,
      // maxWidth: 512,
      // maxHeight: 512,
      androidUiSettings: AndroidUiSettings(
          toolbarColor: Colors.purple,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: Colors.purple,
          
          toolbarTitle: 'Recortar'),
    );

    setState(() {
      _imageFile = cropped ?? _imageFile;
    });
  }

  /// Select an image via gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.gallery) {
      File selected = await ImagePicker.pickImage(source: source);

      setState(() {
        _imageFile = selected;
      });
    } else {
      File selected = await ImagePicker.pickImage(source: source);

      setState(() {
        _imageFile = selected;
        bandera = true;
      });
      Future.delayed(const Duration(seconds: 4), () {
        // Here you can write your code

        setState(() {
          bandera = false;
          visibilidad = true;
        });
      });
    }
  }

  /// Remove image
  void _clear() {
    setState(() => _imageFile = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Select an image from the camera or gallery
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            IconButton(
              iconSize: 30.0,
              color: Colors.blue,
              icon: Icon(Icons.photo_camera),
              onPressed: () => _pickImage(ImageSource.camera),
            ),
            IconButton(
              iconSize: 30.0,
              color: Colors.red,
              icon: Icon(Icons.photo_library),
              onPressed: () => _pickImage(ImageSource.gallery),
            ),
          ],
        ),
      ),

      // Preview the image and crop it
      body: ModalProgressHUD(
        color: Colors.grey[850],
        opacity: 1,
        inAsyncCall: bandera,
        child: ListView(
          children: <Widget>[
            if (_imageFile != null) ...[
              Padding(
                padding: EdgeInsets.all(25.0),
                child: Image.file(_imageFile),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  FlatButton(
                    child: Icon(Icons.crop),
                    onPressed: _cropImage,
                  ),
                  FlatButton(
                    child: Icon(Icons.refresh),
                    onPressed: _clear,
                  ),
                ],
              ),
              Uploader(file: _imageFile)
            ]
          ],
        ),
      ),
    );
  }
}

class Uploader extends StatefulWidget {
  final File file;

  Uploader({this.file});

  createState() => _UploaderState();
}

class _UploaderState extends State<Uploader> {
  final FirebaseStorage _storage =
      FirebaseStorage(storageBucket: 'gs://file-upload-8c74e.appspot.com');

  StorageUploadTask _uploadTask;

  /// Starts an upload task
  void _startUpload() {
    /// Unique file name for the file
    String filePath = 'images/${DateTime.now()}.png';

    setState(() {
      _uploadTask = _storage.ref().child(filePath).putFile(widget.file);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_uploadTask != null) {
      /// Manage the task state and event subscription with a StreamBuilder
      return StreamBuilder<StorageTaskEvent>(
          stream: _uploadTask.events,
          builder: (_, snapshot) {
            var event = snapshot?.data?.snapshot;

            double progressPercent = event != null
                ? event.bytesTransferred / event.totalByteCount
                : 0;

            return Padding(
              padding: EdgeInsets.only(top: 40.0),
              child: Column(
                children: [
                  if (_uploadTask.isComplete)
                    Text(
                      '🎉🎉🎉',
                      style: TextStyle(fontSize: 30.0),
                    ),

                  if (_uploadTask.isPaused)
                    FlatButton(
                      child: Icon(
                        Icons.play_arrow,
                        size: 30.0,
                      ),
                      onPressed: _uploadTask.resume,
                    ),

                  if (_uploadTask.isInProgress)
                    FlatButton(
                      child: Icon(
                        Icons.pause,
                        size: 30.0,
                      ),
                      onPressed: _uploadTask.pause,
                    ),

                  // Progress bar
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 25.0),
                    child: LinearProgressIndicator(value: progressPercent),
                  ),
                  Text(
                    '${(progressPercent * 100).toStringAsFixed(2)} % ',
                    style: TextStyle(fontSize: 30.0),
                  ),
                ],
              ),
            );
          });
    } else {
      // Allows user to decide when to start the upload
      return Container(
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.circular(30.0)
        ),
        margin: EdgeInsets.symmetric(horizontal: 30.0,vertical: 30.0),
        child: FlatButton.icon(
          label: Text('Subir a Firebase'),
          icon: Icon(Icons.cloud_upload),
          onPressed: _startUpload,
        ),
      );
    }
  }
}
