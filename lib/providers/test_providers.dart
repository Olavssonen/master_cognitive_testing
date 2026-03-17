import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_master_app/models/test_definition.dart';
import 'package:flutter_master_app/tests/counter_test.dart';
import 'package:flutter_master_app/tests/tap10_test.dart';
import 'package:flutter_master_app/tests/tmt_test.dart';
import 'package:flutter_master_app/tests/stroop_test.dart';
import 'package:flutter_master_app/tests/cog_test.dart';

final testRegistryProvider = Provider<List<TestDefinition>>((ref) {
  return [
    counterTest,
    tap10Test,
    cogTest,
    tmtTest,
    stroopTest,
  ];
});
