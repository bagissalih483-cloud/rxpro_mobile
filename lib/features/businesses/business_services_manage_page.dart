import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxpro_mobile/app/app_routes.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';
import 'package:rxpro_mobile/core/responsive/rx_keyboard_shortcuts.dart';
import 'package:rxpro_mobile/core/responsive/rx_responsive_grid.dart';
import 'package:flutter/material.dart';

import 'data/business_services_repository.dart';
import 'domain/business_service_form_policy.dart';
import 'presentation/business_service_form_controller.dart';

/// 50C-K2: Business services management Firestore collection/field literals use
/// FirestoreCollections/FirestoreFields constants. Service behavior is unchanged.

part 'business_services_page_part.dart';
part 'business_services_summary_part.dart';
part 'business_services_list_part.dart';
part 'business_service_form_part.dart';
part 'business_services_primitives_part.dart';
