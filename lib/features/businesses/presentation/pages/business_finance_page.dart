import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxpro_mobile/app/app_routes.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';
import 'package:rxpro_mobile/features/finance/data/business_finance_repository.dart';
import 'package:rxpro_mobile/features/businesses/presentation/business_finance_controller.dart';
import 'package:rxpro_mobile/features/businesses/presentation/models/business_finance_models.dart';
import 'package:rxpro_mobile/features/businesses/presentation/utils/business_finance_formatters.dart';
import 'package:rxpro_mobile/features/businesses/presentation/widgets/business_finance_widgets.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

/// 51B-E: Business finance page Firestore collection/field literals use
/// FirestoreCollections/FirestoreFields constants. Behavior is unchanged.

part 'business_finance_shell_part.dart';
part 'business_finance_expense_form_part.dart';
