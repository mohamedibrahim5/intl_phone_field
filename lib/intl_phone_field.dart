library intl_phone_field;

import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/helpers.dart';

import './countries.dart';
import './phone_number.dart';

/// A customizable international phone number input widget
/// with built-in country picker, validation, and formatting.
///
/// This version includes:
/// - Manual or automatic validation
/// - Custom validation logic (sync or async)
/// - Country flag & dropdown selection
/// - Configurable appearance and behavior
class IntlPhoneField extends StatefulWidget {
  /// Optional key for the [FormField].
  final GlobalKey<FormFieldState>? formFieldKey;

  /// Whether to obscure the entered text (e.g., password fields).
  final bool obscureText;

  /// Text alignment.
  final TextAlign textAlign;

  /// Vertical text alignment.
  final TextAlignVertical? textAlignVertical;

  /// Tap callback.
  final VoidCallback? onTap;

  /// If true, prevents editing the text field.
  final bool readOnly;

  /// Callback when the form field is saved.
  final FormFieldSetter<PhoneNumber>? onSaved;

  /// Triggered whenever the phone number changes.
  final ValueChanged<PhoneNumber>? onChanged;

  /// Called when a user changes the selected country.
  final ValueChanged<Country>? onCountryChanged;

  /// A custom validator for the phone number.
  /// Can be synchronous or asynchronous.
  final FutureOr<String?> Function(PhoneNumber?)? validator;

  /// Keyboard type for input.
  final TextInputType keyboardType;

  /// Text editing controller.
  final TextEditingController? controller;

  /// Optional focus node.
  final FocusNode? focusNode;

  /// Triggered when the input is submitted.
  final void Function(String)? onSubmitted;

  /// Enables or disables the field.
  final bool enabled;

  /// Keyboard appearance (iOS only).
  final Brightness? keyboardAppearance;

  /// Initial phone number value.
  final String? initialValue;

  /// Language code (e.g. 'en', 'ar').
  final String languageCode;

  /// Two-letter ISO or dial code for initial country.
  final String? initialCountryCode;

  /// Optional list of countries (defaults to built-in list).
  final List<Country>? countries;

  /// Field decoration.
  final InputDecoration decoration;

  /// Text style.
  final TextStyle? style;

  /// Disables automatic length validation.
  final bool disableLengthCheck;

  /// Whether to show the dropdown icon.
  final bool showDropdownIcon;

  /// Decoration for the dropdown button.
  final BoxDecoration dropdownDecoration;

  /// Text style for the country dial code.
  final TextStyle? dropdownTextStyle;

  /// Optional input formatters.
  final List<TextInputFormatter>? inputFormatters;

  /// Text shown in the country search field.
  final String searchText;

  /// Dropdown icon position (leading or trailing).
  final IconPosition dropdownIconPosition;

  /// Icon used for dropdown.
  final Widget dropdownIcon;

  /// Autofocus behavior.
  final bool autofocus;

  /// Autovalidation behavior.
  final AutovalidateMode? autovalidateMode;

  /// Whether to show the country flag.
  final bool showCountryFlag;

  /// Default validation message.
  final String? invalidNumberMessage;

  /// Cursor color.
  final Color? cursorColor;

  /// Cursor height.
  final double? cursorHeight;

  /// Cursor corner radius.
  final Radius? cursorRadius;

  /// Cursor width.
  final double cursorWidth;

  /// Whether to show the cursor.
  final bool? showCursor;

  /// Padding around flag button.
  final EdgeInsetsGeometry flagsButtonPadding;

  /// Keyboard action button (next, done, etc.).
  final TextInputAction? textInputAction;

  /// Optional picker dialog style customization.
  final PickerDialogStyle? pickerDialogStyle;

  /// Margin for flag button.
  final EdgeInsets flagsButtonMargin;

  /// Disables phone autofill hints.
  final bool disableAutoFillHints;

  /// Whether to show character counter.
  final bool counterTextTest;

  /// Custom magnifier config (iOS text selection).
  final TextMagnifierConfiguration? magnifierConfiguration;

  /// Whether to show validation message.
  final bool showValidate;

  /// Enables manual validation mode.
  final bool addValidateManual;

  const IntlPhoneField({
    Key? key,
    this.formFieldKey,
    this.initialCountryCode,
    this.languageCode = 'en',
    this.disableAutoFillHints = false,
    this.obscureText = false,
    this.textAlign = TextAlign.left,
    this.textAlignVertical,
    this.onTap,
    this.readOnly = false,
    this.initialValue,
    this.keyboardType = TextInputType.phone,
    this.controller,
    this.focusNode,
    this.decoration = const InputDecoration(),
    this.style,
    this.dropdownTextStyle,
    this.onSubmitted,
    this.validator,
    this.onChanged,
    this.countries,
    this.onCountryChanged,
    this.onSaved,
    this.showDropdownIcon = true,
    this.dropdownDecoration = const BoxDecoration(),
    this.inputFormatters,
    this.enabled = true,
    this.keyboardAppearance,
    this.searchText = 'Search country',
    this.dropdownIconPosition = IconPosition.leading,
    this.dropdownIcon = const Icon(Icons.arrow_drop_down),
    this.autofocus = false,
    this.textInputAction,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.showCountryFlag = true,
    this.cursorColor,
    this.disableLengthCheck = false,
    this.flagsButtonPadding = EdgeInsets.zero,
    this.invalidNumberMessage = 'Invalid Mobile Number',
    this.cursorHeight,
    this.cursorRadius = Radius.zero,
    this.cursorWidth = 2.0,
    this.showCursor = true,
    this.pickerDialogStyle,
    this.flagsButtonMargin = EdgeInsets.zero,
    this.magnifierConfiguration,
    this.counterTextTest = false,
    this.showValidate = false,
    this.addValidateManual = false,
  }) : super(key: key);

  @override
  State<IntlPhoneField> createState() => _IntlPhoneFieldState();
}

class _IntlPhoneFieldState extends State<IntlPhoneField> {
  late List<Country> _countryList;
  late Country _selectedCountry;
  late List<Country> filteredCountries;
  late String number;

  String? validatorMessage;

  @override
  void initState() {
    super.initState();
    _countryList = widget.countries ?? countries;
    filteredCountries = _countryList;
    number = widget.initialValue ?? '';

    // Detect initial country from provided code or input
    if (widget.initialCountryCode == null && number.startsWith('+')) {
      number = number.substring(1);
      _selectedCountry = countries.firstWhere(
        (country) => number.startsWith(country.fullCountryCode),
        orElse: () => _countryList.first,
      );
      number = number.replaceFirst(
        RegExp("^${_selectedCountry.fullCountryCode}"),
        "",
      );
    } else {
      _selectedCountry = _countryList.firstWhere(
        (item) => item.code == (widget.initialCountryCode ?? 'US'),
        orElse: () => _countryList.first,
      );
      number = number.replaceFirst(
        RegExp("^\\+?${_selectedCountry.fullCountryCode}"),
        "",
      );
    }

    // Pre-run validation for always mode
    if (widget.autovalidateMode == AutovalidateMode.always) {
      final initialPhoneNumber = PhoneNumber(
        countryISOCode: _selectedCountry.code,
        countryCode: '+${_selectedCountry.dialCode}',
        number: widget.initialValue ?? '',
      );
      final value = widget.validator?.call(initialPhoneNumber);
      if (value is String) {
  // Validator returned a normal String message
  validatorMessage = value;
} else if (value is Future<String?>) {
  // Validator returned a Future — handle it safely
  value.then((msg) {
    if (mounted) {
      setState(() => validatorMessage = msg);
    }
  });
}
    }
  }

  /// Opens the country picker dialog.
  Future<void> _changeCountry() async {
    filteredCountries = _countryList;
    await showDialog(
      context: context,
      useRootNavigator: false,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setState) => CountryPickerDialog(
          languageCode: widget.languageCode.toLowerCase(),
          style: widget.pickerDialogStyle,
          filteredCountries: filteredCountries,
          searchText: widget.searchText,
          countryList: _countryList,
          selectedCountry: _selectedCountry,
          onCountryChanged: (Country country) {
            _selectedCountry = country;
            widget.onCountryChanged?.call(country);
            setState(() {});
          },
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: widget.formFieldKey,
      initialValue: (widget.controller == null) ? number : null,
      autofillHints:
          widget.disableAutoFillHints ? null : [AutofillHints.telephoneNumberNational],
      readOnly: widget.readOnly,
      obscureText: widget.obscureText,
      textAlign: widget.textAlign,
      textAlignVertical: widget.textAlignVertical,
      cursorColor: widget.cursorColor,
      onTap: widget.onTap,
      controller: widget.controller,
      focusNode: widget.focusNode,
      cursorHeight: widget.cursorHeight,
      cursorRadius: widget.cursorRadius,
      cursorWidth: widget.cursorWidth,
      showCursor: widget.showCursor,
      onFieldSubmitted: widget.onSubmitted,
      magnifierConfiguration: widget.magnifierConfiguration,
      decoration: widget.decoration.copyWith(
        prefixIcon: _buildFlagsButton(),
        counterText: widget.counterTextTest ? '' : !widget.enabled ? '' : null,
      ),
      style: widget.style,

      /// Handle saving the number in `Form.onSave`
      onSaved: (value) {
        widget.onSaved?.call(
          PhoneNumber(
            countryISOCode: _selectedCountry.code,
            countryCode: '+${_selectedCountry.dialCode}${_selectedCountry.regionCode}',
            number: value ?? '',
          ),
        );
      },

      /// Triggered when user changes input
      onChanged: (value) async {
        final phoneNumber = PhoneNumber(
          countryISOCode: _selectedCountry.code,
          countryCode: '+${_selectedCountry.fullCountryCode}',
          number: value,
        );

        // If auto-validation is enabled, update message
        if (widget.autovalidateMode != AutovalidateMode.disabled) {
          final result = await widget.validator?.call(phoneNumber);
          if (mounted && result is String) {
            setState(() => validatorMessage = result);
          }
        }

        widget.onChanged?.call(phoneNumber);
      },

      /// ✅ FIXED VALIDATOR
      validator: widget.addValidateManual
          ? (value) {
              // If manual validation is enabled, map PhoneNumber -> String?
              final phoneNumber = PhoneNumber(
                countryISOCode: _selectedCountry.code,
                countryCode: '+${_selectedCountry.fullCountryCode}',
                number: value ?? '',
              );
              final result = widget.validator?.call(phoneNumber);
              if (result is Future<String?>) {
                // Async validators can’t be awaited here — handled above
                return null;
              }
              return result as String?;
            }
          : (value) {
              // Default built-in validation
              if (value == null || !isNumeric(value)) return validatorMessage;
              if (!widget.disableLengthCheck) {
                return value.length >= _selectedCountry.minLength &&
                        value.length <= _selectedCountry.maxLength
                    ? null
                    : widget.showValidate
                        ? null
                        : widget.invalidNumberMessage;
              }
              return validatorMessage;
            },

      maxLength: widget.disableLengthCheck ? null : _selectedCountry.maxLength,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      enabled: widget.enabled,
      keyboardAppearance: widget.keyboardAppearance,
      autofocus: widget.autofocus,
      textInputAction: widget.textInputAction,
      autovalidateMode: widget.autovalidateMode,
    );
  }

  /// Builds the country flag & dropdown selector button.
  Container _buildFlagsButton() {
    return Container(
      margin: widget.flagsButtonMargin,
      child: DecoratedBox(
        decoration: widget.dropdownDecoration,
        child: InkWell(
          borderRadius: widget.dropdownDecoration.borderRadius as BorderRadius?,
          onTap: widget.readOnly
              ? null
              : widget.enabled
                  ? _changeCountry
                  : null,
          child: Padding(
            padding: widget.flagsButtonPadding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Dropdown icon (if leading)
                if (widget.enabled &&
                    widget.showDropdownIcon &&
                    widget.dropdownIconPosition == IconPosition.leading) ...[
                  widget.dropdownIcon,
                  const SizedBox(width: 4),
                ],

                // Country flag
                if (widget.showCountryFlag)
                  kIsWeb
                      ? Image.asset(
                          'assets/flags/${_selectedCountry.code.toLowerCase()}.png',
                          package: 'intl_phone_field',
                          width: 32,
                        )
                      : Text(
                          _selectedCountry.flag,
                          style: const TextStyle(fontSize: 18),
                        ),

                const SizedBox(width: 8),

                // Dropdown icon (if trailing)
                if (widget.enabled &&
                    widget.showDropdownIcon &&
                    widget.dropdownIconPosition == IconPosition.trailing) ...[
                  const SizedBox(width: 4),
                  widget.dropdownIcon,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Enum for dropdown icon positioning.
enum IconPosition {
  leading,
  trailing,
}
