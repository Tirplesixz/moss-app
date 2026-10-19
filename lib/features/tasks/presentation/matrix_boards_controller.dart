import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/providers/database_providers.dart';
import '../data/board_repository.dart';
import '../domain/matrix_board.dart';

class MatrixBoardsState {
  final List<MatrixBoard> boards;
  final MatrixBoard activeBoard;
  final bool loading;

  const MatrixBoardsState({
    required this.boards,
    required this.activeBoard,
    this.loading = false,
  });

  MatrixBoardsState copyWith({
    List<MatrixBoard>? boards,
    MatrixBoard? activeBoard,
    bool? loading,
  }) {
    return MatrixBoardsState(
      boards: boards ?? this.boards,
      activeBoard: activeBoard ?? this.activeBoard,
      loading: loading ?? this.loading,
    );
  }
}

class MatrixBoardsController extends StateNotifier<MatrixBoardsState> {
  final BoardRepository _repository;

  MatrixBoardsController(this._repository)
      : super(
          MatrixBoardsState(
            boards: MatrixBoard.createDefaults(),
            activeBoard: MatrixBoard.createDefaults().first,
            loading: true,
          ),
        ) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true);
    final boards = await _repository.getAllBoards();
    final active = boards.firstWhere(
      (b) => b.id == state.activeBoard.id,
      orElse: () => boards.first,
    );
    state = MatrixBoardsState(
      boards: boards,
      activeBoard: active,
      loading: false,
    );
  }

  void selectBoard(MatrixBoard board) {
    state = state.copyWith(activeBoard: board);
  }

  Future<MatrixBoard> createBoard({
    required String name,
    required int iconCode,
    required int colorValue,
    String? q1Name,
    String? q2Name,
    String? q3Name,
    String? q4Name,
  }) async {
    final now = DateTime.now().toUtc();
    final newBoard = MatrixBoard(
      id: const Uuid().v4(),
      name: name,
      iconCode: iconCode,
      colorValue: colorValue,
      q1Name: q1Name ?? 'สำคัญและเร่งด่วน',
      q2Name: q2Name ?? 'สำคัญ',
      q3Name: q3Name ?? 'เร่งด่วน',
      q4Name: q4Name ?? 'สักวันหนึ่ง',
      isDefault: false,
      createdAt: now,
      updatedAt: now,
    );
    await _repository.saveBoard(newBoard);
    await load();
    selectBoard(newBoard);
    return newBoard;
  }

  Future<void> updateBoard(MatrixBoard board) async {
    final updated = board.copyWith(updatedAt: DateTime.now().toUtc());
    await _repository.updateBoard(updated);
    await load();
  }

  Future<void> deleteBoard(String id) async {
    await _repository.deleteBoard(id);
    await load();
    if (state.activeBoard.id == id) {
      state = state.copyWith(activeBoard: state.boards.first);
    }
  }
}

final matrixBoardsControllerProvider =
    StateNotifierProvider<MatrixBoardsController, MatrixBoardsState>((ref) {
  final repo = ref.watch(boardRepositoryProvider);
  return MatrixBoardsController(repo);
});
