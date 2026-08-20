import 'dart:math';

class UnitConverter {
  // Currency conversions (base: USD) - Note: These are example rates and should be updated with real API
  static final Map<String, double> currencyUnits = {
    'US Dollar (USD)': 1.0,
    'Euro (EUR)': 0.92,
    'British Pound (GBP)': 0.79,
    'Japanese Yen (JPY)': 149.50,
    'Indian Rupee (INR)': 83.12,
    'Canadian Dollar (CAD)': 1.35,
    'Australian Dollar (AUD)': 1.52,
    'Swiss Franc (CHF)': 0.88,
    'Chinese Yuan (CNY)': 7.24,
    'Mexican Peso (MXN)': 17.08,
  };

  // Length conversions (base: meter)
  static final Map<String, double> lengthUnits = {
    'Meter (m)': 1.0,
    'Kilometer (km)': 0.001,
    'Centimeter (cm)': 100.0,
    'Millimeter (mm)': 1000.0,
    'Mile (mi)': 0.000621371,
    'Yard (yd)': 1.09361,
    'Foot (ft)': 3.28084,
    'Inch (in)': 39.3701,
  };

  // Area conversions (base: square meter)
  static final Map<String, double> areaUnits = {
    'Square Meter (m²)': 1.0,
    'Square Kilometer (km²)': 0.000001,
    'Square Centimeter (cm²)': 10000.0,
    'Square Mile (mi²)': 3.861e-7,
    'Square Yard (yd²)': 1.19599,
    'Square Foot (ft²)': 10.7639,
    'Square Inch (in²)': 1550.0,
    'Hectare (ha)': 0.0001,
    'Acre': 0.000247105,
  };

  // Volume conversions (base: liter)
  static final Map<String, double> volumeUnits = {
    'Liter (L)': 1.0,
    'Milliliter (mL)': 1000.0,
    'Cubic Meter (m³)': 0.001,
    'Cubic Centimeter (cm³)': 1000.0,
    'Gallon (US)': 0.264172,
    'Quart (US)': 1.05669,
    'Pint (US)': 2.11338,
    'Cup (US)': 4.22675,
    'Fluid Ounce (US)': 33.814,
  };

  // Weight conversions (base: kilogram)
  static final Map<String, double> weightUnits = {
    'Kilogram (kg)': 1.0,
    'Gram (g)': 1000.0,
    'Milligram (mg)': 1000000.0,
    'Metric Ton (t)': 0.001,
    'Pound (lb)': 2.20462,
    'Ounce (oz)': 35.274,
    'Stone (st)': 0.157473,
    'Ton (US)': 0.00110231,
  };

  // Speed conversions (base: m/s)
  static final Map<String, double> speedUnits = {
    'Meter/Second (m/s)': 1.0,
    'Kilometer/Hour (km/h)': 3.6,
    'Mile/Hour (mph)': 2.23694,
    'Foot/Second (ft/s)': 3.28084,
    'Knot (kn)': 1.94384,
  };

  // Pressure conversions (base: pascal)
  static final Map<String, double> pressureUnits = {
    'Pascal (Pa)': 1.0,
    'Kilopascal (kPa)': 0.001,
    'Bar': 0.00001,
    'PSI': 0.000145038,
    'Atmosphere (atm)': 9.8692e-6,
    'Torr': 0.00750062,
  };

  // Power conversions (base: watt)
  static final Map<String, double> powerUnits = {
    'Watt (W)': 1.0,
    'Kilowatt (kW)': 0.001,
    'Megawatt (MW)': 0.000001,
    'Horsepower (hp)': 0.00134102,
    'BTU/hour': 3.41214,
  };

  static double convert(double value, String fromUnit, String toUnit, String category) {
    Map<String, double> units;

    switch (category) {
      case 'Currency':
        units = currencyUnits;
        break;
      case 'Length':
        units = lengthUnits;
        break;
      case 'Area':
        units = areaUnits;
        break;
      case 'Volume':
        units = volumeUnits;
        break;
      case 'Weight':
        units = weightUnits;
        break;
      case 'Speed':
        units = speedUnits;
        break;
      case 'Pressure':
        units = pressureUnits;
        break;
      case 'Power':
        units = powerUnits;
        break;
      default:
        return value;
    }

    // Convert to base unit first, then to target unit
    double baseValue = value / units[fromUnit]!;
    return baseValue * units[toUnit]!;
  }

  static double convertTemperature(double value, String from, String to) {
    // Convert to Celsius first
    double celsius;
    switch (from) {
      case 'Celsius (°C)':
        celsius = value;
        break;
      case 'Fahrenheit (°F)':
        celsius = (value - 32) * 5 / 9;
        break;
      case 'Kelvin (K)':
        celsius = value - 273.15;
        break;
      default:
        celsius = value;
    }

    // Convert from Celsius to target
    switch (to) {
      case 'Celsius (°C)':
        return celsius;
      case 'Fahrenheit (°F)':
        return celsius * 9 / 5 + 32;
      case 'Kelvin (K)':
        return celsius + 273.15;
      default:
        return celsius;
    }
  }

  static String convertNumberSystem(String value, String from, String to) {
    try {
      int decimal;

      // Convert to decimal first
      switch (from) {
        case 'Decimal':
          decimal = int.parse(value);
          break;
        case 'Binary':
          decimal = int.parse(value, radix: 2);
          break;
        case 'Octal':
          decimal = int.parse(value, radix: 8);
          break;
        case 'Hexadecimal':
          decimal = int.parse(value, radix: 16);
          break;
        default:
          return value;
      }

      // Convert from decimal to target
      switch (to) {
        case 'Decimal':
          return decimal.toString();
        case 'Binary':
          return decimal.toRadixString(2);
        case 'Octal':
          return decimal.toRadixString(8);
        case 'Hexadecimal':
          return decimal.toRadixString(16).toUpperCase();
        default:
          return decimal.toString();
      }
    } catch (e) {
      return 'Error';
    }
  }

  static Map<String, List<String>> getUnitsForCategory(String category) {
    switch (category) {
      case 'Currency':
        return {'units': currencyUnits.keys.toList()};
      case 'Length':
        return {'units': lengthUnits.keys.toList()};
      case 'Area':
        return {'units': areaUnits.keys.toList()};
      case 'Volume':
        return {'units': volumeUnits.keys.toList()};
      case 'Weight':
        return {'units': weightUnits.keys.toList()};
      case 'Speed':
        return {'units': speedUnits.keys.toList()};
      case 'Pressure':
        return {'units': pressureUnits.keys.toList()};
      case 'Power':
        return {'units': powerUnits.keys.toList()};
      case 'Temperature':
        return {'units': ['Celsius (°C)', 'Fahrenheit (°F)', 'Kelvin (K)']};
      case 'Number system':
        return {'units': ['Decimal', 'Binary', 'Octal', 'Hexadecimal']};
      default:
        return {'units': []};
    }
  }
}