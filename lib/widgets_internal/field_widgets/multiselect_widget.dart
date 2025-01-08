import 'package:championforms/controllers/form_controller.dart';
import 'package:flutter/material.dart';

class MultiselectWidget extends StatefulWidget {
  const MultiselectWidget({
    super.key,
    required this.id,
    required this.child,
    required this.controller,
    this.requestFocus = false,
  });
  final String id;
  final Widget child;
  final ChampionFormController controller;
  final bool requestFocus;
  @override
  State<StatefulWidget> createState() => _MultiselectWidgetState();
}

class _MultiselectWidgetState extends State<MultiselectWidget> {
  late FocusNode _focusNode;
  //late bool _gotFocus;
  late ValueKey<String> _focusKey;

  @override
  void initState() {
    super.initState();

    _focusKey = ValueKey("${widget.id}traversalgroup");

    //_gotFocus = false;

    _focusNode = FocusNode();

    _focusNode.addListener(_onLoseFocus);

    if (widget.requestFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _requestFocusOnFirstChild();
      });
    }
  }

  void _requestFocusOnFirstChild() {
    // Replace 'myFocusScope' with the actual ValueKey string for your FocusScope
    _focusNode.requestFocus();
    FocusScope.of(context).nextFocus();
  }

  void _onLoseFocus() {
    // transmit focus state to provider
    widget.controller.setFieldFocus(widget.id, _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      key: _focusKey,
      descendantsAreTraversable: true,
      descendantsAreFocusable: true,
      skipTraversal: true,
      focusNode: _focusNode,
      child: widget.child,
    );
  }
}
