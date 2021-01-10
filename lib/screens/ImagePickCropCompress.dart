import 'package:flutter/material.dart';

import 'dart:io';
import 'package:image_crop/image_crop.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickCropCompress extends StatefulWidget {
  @override
  _ImagePickCropCompressState createState() => _ImagePickCropCompressState();
}

class _ImagePickCropCompressState extends State<ImagePickCropCompress> {
  final cropKey = GlobalKey<CropState>();
  File _file;
  File _sample;
  File _lastImage;

  bool _isSquare = false;

  @override
  void initState() {
    super.initState();
    _openImage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
          child: _sample == null ? Container() : _buildCroppingImage(),
        ),
      ),
    );
  }

  Widget _buildCroppingImage() {
    return Column(
      children: <Widget>[
        Container(
          alignment: AlignmentDirectional.center,
          padding: const EdgeInsets.only(top: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[doneButtonConditions()],
          ),
        ),
        Expanded(
          child: Crop.file(
            _sample,
            key: cropKey,
            alwaysShowGrid: true,
            aspectRatio: 1.0,
          ),
        ),
        Container(
          alignment: AlignmentDirectional.center,
          padding: const EdgeInsets.only(top: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              FlatButton(
                child: Text(
                  'Crop',
                  style: Theme.of(context)
                      .textTheme
                      .button
                      .copyWith(color: Colors.white),
                ),
                onPressed: () => _cropImage(),
              ),
              FlatButton(
                child: Text(
                  'Choose Image',
                  style: Theme.of(context)
                      .textTheme
                      .button
                      .copyWith(color: Colors.white),
                ),
                onPressed: () => _openImage(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  //Select from Gallery
  Future<void> _openImage() async {
    final file = await ImagePicker.pickImage(source: ImageSource.gallery);

    final sample = await ImageCrop.sampleImage(
      file: file,
      preferredSize: 2000,
    );

    setState(() {
      _sample = sample;
      _file = file;
      _lastImage = _sample;
    });
    await isSquareImage();
  }

  //Crop image after selection
  Future<void> _cropImage() async {
    final scale = cropKey.currentState.scale;
    final area = cropKey.currentState.area;
    _lastImage = _file;

    if (area == null) {
      return;
    }

    if (area != null) {
      if (!await pixelMoreThanMin()) {
        _file = _lastImage;
        print("Image replaced");
        return;
      }
    }

    final sample = await ImageCrop.sampleImage(
      file: _file,
      preferredSize: (2000 / scale).round(),
    );

    final file = await ImageCrop.cropImage(
      file: sample,
      area: area,
    );

    setState(() {
      _file = file;
      _sample = file;
    });
    await isSquareImage();
  }

  Widget doneButtonConditions() {
    if (_isSquare) {
      return FlatButton(
        child: Text(
          'Save',
          style:
              Theme.of(context).textTheme.button.copyWith(color: Colors.white),
        ),
        onPressed: () => Navigator.pop(context, _sample),
      );
    }
    return Container();
  }

  Future<bool> pixelMoreThanMin() async {
    final options = await ImageCrop.getImageOptions(file: _sample);
    if (options.height < 400 && options.width < 400) return false;
    return true;
  }

  Future<bool> isSquareImage() async {
    final options = await ImageCrop.getImageOptions(file: _sample);
    if (options.height == options.width) {
      setState(() {
        _isSquare = true;
      });
      return true;
    }
    return false;
  }
}
