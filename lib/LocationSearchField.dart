import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

class LocationSearchField extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onPlaceSelected;
  final String apiKey;

  const LocationSearchField({
    required this.onPlaceSelected,
    required this.apiKey,
    Key? key,
  }) : super(key: key);

  @override
  _LocationSearchFieldState createState() => _LocationSearchFieldState();
}

class _LocationSearchFieldState extends State<LocationSearchField> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _predictions = [];
  bool _isLoading = false;
  FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() {
          _predictions = [];
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _getPlacePredictions(String input) async {
    if (input.length < 3) {
      setState(() {
        _predictions = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=${widget.apiKey}&components=country:de';
      final response = await http.get(Uri.parse(url));
      final json = convert.jsonDecode(response.body);

      if (json['status'] == 'OK') {
        setState(() {
          _predictions = json['predictions'];
        });
      } else {
        setState(() {
          _predictions = [];
        });
      }
    } catch (e) {
      print('Error getting place predictions: $e');


      setState(() {
        _predictions = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getPlaceDetails(String placeId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final url =
          'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=${widget.apiKey}';
      final response = await http.get(Uri.parse(url));
      final json = convert.jsonDecode(response.body);

      if (json['status'] == 'OK') {
        final result = json['result'];
        widget.onPlaceSelected({
          'address': result['formatted_address'],
          'latitude': result['geometry']['location']['lat'],
          'longitude': result['geometry']['location']['lng'],
          'placeId': placeId,
        });
        _controller.text = result['formatted_address'];
        setState(() {
          _predictions = [];
        });
      }
    } catch (e) {
      print('Error getting place details: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: 'Search for an address',
            hintText: 'Enter an address in Germany',
            prefixIcon: Icon(Icons.search),
            suffixIcon: _isLoading
                ? Padding(
              padding: EdgeInsets.all(10),
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : null,
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _getPlacePredictions(value),
        ),
        if (_predictions.isNotEmpty)
          Container(
            margin: EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _predictions.length,
              separatorBuilder: (_, __) => Divider(height: 1),
              itemBuilder: (context, index) {
                final prediction = _predictions[index];
                return ListTile(
                  leading: Icon(Icons.location_on, size: 20),
                  title: Text(prediction['description']),
                  onTap: () => _getPlaceDetails(prediction['place_id']),
                );
              },
            ),
          ),
      ],
    );
  }
}