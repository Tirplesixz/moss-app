import 'package:flutter_test/flutter_test.dart';
import 'package:moss/core/validation/input_limits.dart';

void main() {
  test('counts user-perceived characters and rejects oversized input', () {
    expect(
      () => InputLimits.requireAtMost(
        List.filled(InputLimits.taskTitle + 1, 'ก').join(),
        InputLimits.taskTitle,
        'title',
      ),
      throwsArgumentError,
    );
    expect(
      () => InputLimits.requireAtMost('👩🏽‍💻', 1, 'title'),
      returnsNormally,
    );
  });

  test('rejects blank required values', () {
    expect(
      () => InputLimits.requireNonBlank('   ', 'title'),
      throwsArgumentError,
    );
  });
}
