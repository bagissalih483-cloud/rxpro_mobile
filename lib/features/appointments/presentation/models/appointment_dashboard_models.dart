import 'package:flutter/material.dart';

class AppointmentRoleContext {
  const AppointmentRoleContext.customer() : isBusiness = false, business = null;

  const AppointmentRoleContext.business(this.business) : isBusiness = true;

  final bool isBusiness;
  final AppointmentBusinessLite? business;
}

class AppointmentBusinessLite {
  const AppointmentBusinessLite({
    required this.id,
    required this.name,
    required this.data,
  });

  final String id;
  final String name;
  final Map<String, dynamic> data;
}

class AppointmentStaffLite {
  const AppointmentStaffLite({required this.id, required this.name});

  final String id;
  final String name;
}

class AppointmentLegendItem {
  const AppointmentLegendItem(this.label, this.color);

  final String label;
  final Color color;
}
