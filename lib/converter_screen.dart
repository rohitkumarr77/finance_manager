import 'package:flutter/material.dart';
import 'unit_converter.dart';

class ConverterScreen extends StatefulWidget {
  final String converterType;

  const ConverterScreen({Key? key, required this.converterType}) : super(key: key);

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  TextEditingController inputController = TextEditingController();
  String fromUnit = '';
  String toUnit = '';
  String result = '0';
  List<String> units = [];

  @override
  void initState() {
    super.initState();
    units = UnitConverter.getUnitsForCategory(widget.converterType)['units']!;
    if (units.isNotEmpty) {
      fromUnit = units[0];
      toUnit = units.length > 1 ? units[1] : units[0];
    }
    inputController.addListener(_convert);
  }

  @override
  void dispose() {
    inputController.dispose();
    super.dispose();
  }

  void _convert() {
    if (inputController.text.isEmpty) {
      setState(() {
        result = '0';
      });
      return;
    }

    try {
      double value = double.parse(inputController.text);
      double converted;

      if (widget.converterType == 'Temperature') {
        converted = UnitConverter.convertTemperature(value, fromUnit, toUnit);
      } else if (widget.converterType == 'Number system') {
        setState(() {
          result = UnitConverter.convertNumberSystem(inputController.text, fromUnit, toUnit);
        });
        return;
      } else {
        converted = UnitConverter.convert(value, fromUnit, toUnit, widget.converterType);
      }

      setState(() {
        if (converted == converted.toInt().toDouble()) {
          result = converted.toInt().toString();
        } else {
          result = converted.toStringAsFixed(6).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
        }
      });
    } catch (e) {
      setState(() {
        result = 'Error';
      });
    }
  }

  void _swapUnits() {
    setState(() {
      String temp = fromUnit;
      fromUnit = toUnit;
      toUnit = temp;
      _convert();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.converterType,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // From Unit
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButton<String>(
                    value: fromUnit,
                    dropdownColor: Colors.grey[850],
                    isExpanded: true,
                    underline: Container(),
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                    items: units.map((String unit) {
                      return DropdownMenuItem<String>(
                        value: unit,
                        child: Text(unit),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        fromUnit = newValue!;
                        _convert();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: inputController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w300,
                    ),
                    keyboardType: widget.converterType == 'Number system'
                        ? TextInputType.text
                        : const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '0',
                      hintStyle: TextStyle(color: Colors.white30),
                    ),
                  ),
                ],
              ),
            ),

            // Swap Button
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: IconButton(
                onPressed: _swapUnits,
                icon: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.swap_vert,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),

            // To Unit
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButton<String>(
                    value: toUnit,
                    dropdownColor: Colors.grey[850],
                    isExpanded: true,
                    underline: Container(),
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                    items: units.map((String unit) {
                      return DropdownMenuItem<String>(
                        value: unit,
                        child: Text(unit),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        toUnit = newValue!;
                        _convert();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    result,
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 32,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Number pad for easier input
            if (widget.converterType != 'Number system') _buildNumberPad(),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Row(
            children: [
              _buildPadButton('7'),
              _buildPadButton('8'),
              _buildPadButton('9'),
              _buildPadButton('⌫', color: Colors.grey[800]!),
            ],
          ),
          Row(
            children: [
              _buildPadButton('4'),
              _buildPadButton('5'),
              _buildPadButton('6'),
              _buildPadButton('C', color: Colors.grey[800]!),
            ],
          ),
          Row(
            children: [
              _buildPadButton('1'),
              _buildPadButton('2'),
              _buildPadButton('3'),
              _buildPadButton('.'),
            ],
          ),
          Row(
            children: [
              _buildPadButton('0', flex: 2),
              _buildPadButton('00'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPadButton(String text, {Color? color, int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Material(
          color: color ?? Colors.grey[850],
          borderRadius: BorderRadius.circular(50),
          child: InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: () {
              setState(() {
                if (text == '⌫') {
                  if (inputController.text.isNotEmpty) {
                    inputController.text = inputController.text.substring(
                      0,
                      inputController.text.length - 1,
                    );
                  }
                } else if (text == 'C') {
                  inputController.clear();
                } else {
                  inputController.text += text;
                }
              });
            },
            child: Container(
              height: 60,
              alignment: Alignment.center,
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}