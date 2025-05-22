import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/friend.dart';
import '../../services/mode_service.dart';
import '../../utils/app_colors.dart';

class FriendSearchScreen extends StatefulWidget {
  const FriendSearchScreen({super.key});

  @override
  State<FriendSearchScreen> createState() => _FriendSearchScreenState();
}

class _FriendSearchScreenState extends State<FriendSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Friend? _selectedFriend;
  List<Friend> _searchResults = [];
  bool _isSearching = false;
  int? _selectedRecordId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  final appState = Provider.of<AppState>(context);

  return Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Text(
        '친구 검색',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF333333),
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Color(0xFF52A486)),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          color: Colors.white,
        ),
      ),
      // mode_select_screen과 동일한 디자인으로 bottom 부분 적용
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(70),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 8.0),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xFF52A486).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Color(0xFF52A486).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Color(0xFF52A486).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.terrain,
                    color: Color(0xFF52A486),
                    size: 14,
                  ),
                ),
                SizedBox(width: 10),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appState.selectedMountain ?? '선택된 산 없음',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 1),
                      Text(
                        appState.selectedRoute?.name ?? '선택된 등산로 없음',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    // 바디 부분을 SingleChildScrollView로 감싸 bottom overflow 에러 방지
    body: Container(
      color: Colors.white,
      child: Column(
        children: [
          // 친구와 함께 등산하세요 섹션 - 스크롤 가능한 부분 위에 배치
          Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
                Icon(
                  Icons.people_alt_rounded, 
                  size: 18,
                  color: Color(0xFF52A486),
                ),
                SizedBox(width: 6),
                Text(
                  '친구와 함께 등산하세요',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),
          
          // 검색창
          Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color(0xFFE0E0E0),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '친구의 닉네임을 검색해보세요',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.search,
                      color: Color(0xFF52A486),
                      size: 20,
                    ),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[400], size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                          });
                        },
                      )
                    : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  fillColor: Colors.white,
                  filled: true,
                ),
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF333333),
                ),
                onSubmitted: (value) => _searchFriends(value, appState),
                textInputAction: TextInputAction.search,
              ),
            ),
          ),
          
          // 구분선
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
            child: Container(
              height: 1,
              color: Colors.grey[200],
            ),
          ),
          
          // 검색 결과 영역 - Expanded로 남은 공간 채우기
          Expanded(
            child: _isSearching
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF52A486)),
                          strokeWidth: 3,
                        ),
                      ],
                    ),
                  )
                : _searchController.text.isNotEmpty && _searchResults.isEmpty
                    ? _buildEmptySearchResult()
                    : _searchResults.isEmpty
                        ? _buildInitialSearchState()
                        : ListView.builder(
                            itemCount: _searchResults.length,
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            physics: BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              final friend = _searchResults[index];
                              final isSelected = _selectedFriend?.id == friend.id;
                              final isPossible = friend.isPossible;

                              // 친구 리스트 아이템 부분만 수정
                              return Container(
                                margin: EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  onTap: () {
                                    if (!isPossible) {
                                      _showNotPossibleDialog(context, friend.nickname);
                                      return;
                                    }
                                    
                                    setState(() {
                                      // 이미 선택된 친구를 다시 클릭하면 선택 취소
                                      if (_selectedFriend?.id == friend.id) {
                                        _selectedFriend = null;
                                      } else {
                                        _selectedFriend = friend;
                                      }
                                    });
                              },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      // 기본 상태에서는 흰색 배경과 가벼운 테두리
                                      color: isSelected ? Color(0xFFE6F4EE) : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isSelected
                                              ? Color(0xFF52A486).withOpacity(0.15)
                                              : Colors.black.withOpacity(0.03),
                                          blurRadius: isSelected ? 8 : 4,
                                          offset: Offset(0, 2),
                                          spreadRadius: isSelected ? 1 : 0,
                                        ),
                                      ],
                                      border: Border.all(
                                        // 선택 여부에 따라 테두리 색상과 두께 차이
                                        color: isSelected ? Color(0xFF52A486) : Color(0xFFE0E0E0),
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          // 프로필 이미지 - 선택 시 스타일 변경
                                          Stack(
                                            children: [
                                              Container(
                                                width: 52,
                                                height: 52,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  // 프로필 배경색 - 선택 여부에 따라 변경
                                                  color: isSelected 
                                                      ? Color(0xFF52A486).withOpacity(0.12) 
                                                      : Colors.grey.shade100,
                                                  border: Border.all(
                                                    // 프로필 테두리 - 선택 여부에 따라 변경
                                                    color: isSelected 
                                                        ? Color(0xFF52A486) 
                                                        : Colors.grey.shade300,
                                                    width: isSelected ? 2 : 1,
                                                  ),
                                                  boxShadow: isSelected ? [
                                                    BoxShadow(
                                                      color: Color(0xFF52A486).withOpacity(0.1),
                                                      blurRadius: 6,
                                                      offset: Offset(0, 2),
                                                    ),
                                                  ] : [],
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(26),
                                                  child: friend.profileImg != null && friend.profileImg!.isNotEmpty
                                                      ? Image.network(
                                                          friend.profileImg!,
                                                          width: 52,
                                                          height: 52,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (context, error, stackTrace) {
                                                            return Center(
                                                              child: Text(
                                                                friend.nickname.isNotEmpty
                                                                    ? friend.nickname[0].toUpperCase()
                                                                    : "?",
                                                                style: TextStyle(
                                                                  color: isSelected 
                                                                      ? Color(0xFF52A486) 
                                                                      : Colors.grey.shade600,
                                                                  fontSize: 22,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                          loadingBuilder: (context, child, loadingProgress) {
                                                            if (loadingProgress == null) {
                                                              return child;
                                                            }
                                                            return Center(
                                                              child: CircularProgressIndicator(
                                                                color: Color(0xFF52A486),
                                                                strokeWidth: 2,
                                                                value: loadingProgress.expectedTotalBytes != null
                                                                    ? loadingProgress.cumulativeBytesLoaded /
                                                                        loadingProgress.expectedTotalBytes!
                                                                    : null,
                                                              ),
                                                            );
                                                          },
                                                        )
                                                      : Center(
                                                          child: Text(
                                                            friend.nickname.isNotEmpty
                                                                ? friend.nickname[0].toUpperCase()
                                                                : "?",
                                                            style: TextStyle(
                                                              color: isSelected 
                                                                  ? Color(0xFF52A486) 
                                                                  : Colors.grey.shade600,
                                                              fontSize: 22,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                ),
                                              ),
                                              // 선택 표시 아이콘 - 선택된 경우에만 표시
                                              if (isSelected)
                                                Positioned(
                                                  right: 0,
                                                  bottom: 0,
                                                  child: Container(
                                                    padding: EdgeInsets.all(2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      shape: BoxShape.circle,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black.withOpacity(0.1),
                                                          blurRadius: 2,
                                                          spreadRadius: 1,
                                                        ),
                                                      ],
                                                    ),
                                                    child: Icon(
                                                      Icons.check_circle,
                                                      color: Color(0xFF52A486),
                                                      size: 18,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // 이름 - 선택 시 색상 변경
                                                Text(
                                                  friend.nickname,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: isSelected ? Color(0xFF52A486) : Color(0xFF333333),
                                                  ),
                                                ),
                                                SizedBox(height: 6),
                                                // 상태 표시 뱃지 - 이 부분은 선택 여부와 관계없이 '등산 기록 있음/없음'에 따라 스타일 설정
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: isPossible ? Color(0xFF52A486).withOpacity(0.15) : Color(0xFFFFEFEF),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color: isPossible 
                                                        ? Color(0xFF52A486).withOpacity(0.3) 
                                                        : Color(0xFFFF5151).withOpacity(0.3),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        isPossible ? Icons.check_circle_outline : Icons.cancel_outlined,
                                                        size: 12,
                                                        color: isPossible ? Color(0xFF2B8A6A) : Color(0xFFFF5151),
                                                      ),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        isPossible ? '등산 기록 있음' : '등산 기록 없음',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w500,
                                                          color: isPossible ? Color(0xFF2B8A6A) : Color(0xFFFF5151),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // 선택 시 오른쪽에 표시되는 아이콘 추가
                                          if (isSelected)
                                            Container(
                                              margin: EdgeInsets.only(left: 8),
                                              child: Icon(
                                                Icons.arrow_forward_ios,
                                                size: 14,
                                                color: Color(0xFF52A486),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                                                          },
                                                        ),
          ),
          
          // 하단 선택 완료 버튼
          if (_searchResults.isNotEmpty)
            Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _selectedFriend != null && _selectedFriend!.isPossible
                      ? () => _showFriendTrackingOptionsModal(context, appState)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF52A486),
                    disabledBackgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    '선택 완료',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

// 초기 검색 상태 위젯
Widget _buildInitialSearchState() {
  return Center(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Color(0xFF52A486).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_alt_rounded,
              size: 40,
              color: Color(0xFF52A486).withOpacity(0.5),
            ),
          ),
          SizedBox(height: 16),
          Text(
            '친구를 검색해보세요',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          SizedBox(height: 8),
          Text(
            '친구의 닉네임을 입력하고 선택해주세요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    ),
  );
}

// 검색 결과 없음 위젯
Widget _buildEmptySearchResult() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Color(0xFF52A486).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.search_off,
            size: 40,
            color: Color(0xFF52A486),
          ),
        ),
        SizedBox(height: 16),
        Text(
          '검색 결과가 없습니다',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        SizedBox(height: 8),
        Text(
          '닉네임을 정확히 입력했는지 확인해보세요',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
      ],
    ),
  );
}

  Future<void> _searchFriends(String query, AppState appState) async {
  if (query.isEmpty) return;

  setState(() {
    _isSearching = true;
    _selectedFriend = null; // 중요: 검색 시 선택 초기화
  });

  try {
    final modeService = ModeService();
    final token = appState.accessToken ?? '';
    final mountainId = appState.selectedRoute?.mountainId ?? 0;
    final pathId = appState.selectedRoute?.id ?? 0;

    final results = await modeService.searchFriends(
      query,
      token,
      mountainId: mountainId,
      pathId: pathId,
    );

    setState(() {
      _searchResults = results;
      _isSearching = false;
      // 자동 선택 없음 - 사용자가 직접 선택하도록 함
    });
  } catch (e) {
    debugPrint('친구 검색 오류: $e');
    setState(() {
      _searchResults = [];
      _isSearching = false;
      _selectedFriend = null; // 오류 시에도 선택 초기화
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('친구 검색 중 오류가 발생했습니다'),
          backgroundColor: Color(0xFFFF5151),
        ),
      );
    }
  }
}

  Future<void> _showFriendTrackingOptionsModal(
      BuildContext context, AppState appState) async {
    if (_selectedFriend == null) return;

    final modeService = ModeService();
    _selectedRecordId = null;

    try {
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF52A486)),
              ),
            );
          },
        );
      }

      final mountainId = appState.selectedRoute?.mountainId ?? 0;
      final pathId = appState.selectedRoute?.id ?? 0;
      final token = appState.accessToken ?? '';
      final opponentId = _selectedFriend!.id.toInt();

      final recordsList = await modeService.getFriendTrackingOptions(
        mountainId: mountainId.toInt(),
        pathId: pathId.toInt(),
        opponentId: opponentId,
        token: token,
      );

      if (!mounted) return;
      if (context.mounted) Navigator.of(context).pop();

      if (recordsList.isEmpty) {
        if (!mounted) return;
        if (context.mounted) {
          _showNoRecordsDialog(context);
        }
        return;
      }

      if (!mounted) return;
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24), // Increased radius
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24), // Adjusted padding
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 헤더 부분
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Color(0xFF52A486).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.directions_walk_rounded,
                                color: Color(0xFF52A486),
                                size: 22,
                              ),
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_selectedFriend!.nickname}님의',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF52A486),
                                    ),
                                  ),
                                  Text(
                                    '등산 기록',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF333333),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // 구분선
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Container(
                            height: 1,
                            color: Color(0xFFEEEEEE),
                          ),
                        ),
                        // 선택 안내 텍스트
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: 6),
                              Text(
                                '비교할 기록을 선택해주세요',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 리스트
                        Container(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.4,
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: recordsList.length,
                            itemBuilder: (context, index) {
                              final record = recordsList[index];
                              final recordId = record['recordId'];
                              final date = record['date'];
                              final time = record['time'];

                              final isSelected = _selectedRecordId == recordId;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedRecordId = recordId;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Color(0xFF52A486).withOpacity(0.08)
                                          : Colors.grey[50],
                                      border: Border.all(
                                        color: isSelected ? Color(0xFF52A486) : Colors.grey.shade200,
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: Color(0xFF52A486).withOpacity(0.1),
                                                blurRadius: 4,
                                                offset: Offset(0, 2),
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isSelected ? Color(0xFF52A486) : Colors.white,
                                            border: Border.all(
                                              color: isSelected ? Color(0xFF52A486) : Colors.grey.shade400,
                                              width: 1.5,
                                            ),
                                            boxShadow: isSelected
                                                ? [
                                                    BoxShadow(
                                                      color: Color(0xFF52A486).withOpacity(0.15),
                                                      blurRadius: 4,
                                                      spreadRadius: 1,
                                                    )
                                                  ]
                                                : null,
                                          ),
                                          child: isSelected
                                              ? Icon(
                                                  Icons.check,
                                                  color: Colors.white,
                                                  size: 12,
                                                )
                                              : null,
                                        ),
                                        SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    date,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 15,
                                                      color: isSelected ? Color(0xFF52A486) : Color(0xFF333333),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: isSelected
                                                          ? Color(0xFF52A486).withOpacity(0.1)
                                                          : Colors.grey[100],
                                                      borderRadius: BorderRadius.circular(30),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.access_time_rounded,
                                                          size: 10,
                                                          color: isSelected ? Color(0xFF52A486) : Colors.grey[700],
                                                        ),
                                                        SizedBox(width: 3),
                                                        Text(
                                                          _formatMinutes(time),
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w500,
                                                            color: isSelected ? Color(0xFF52A486) : Colors.grey[700],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 20),
                        Row(
                          children: [
                            // 취소 버튼
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                child: Text(
                                  '취소',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 10), // 버튼 사이 간격
                            // 시작하기 버튼
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _selectedRecordId != null
                                    ? () {
                                        final selectedRecord = recordsList.firstWhere(
                                          (record) => record['recordId'] == _selectedRecordId,
                                        );

                                        appState.setOpponentRecordData(
                                          date: selectedRecord['date'],
                                          time: selectedRecord['time'],
                                          maxHeartRate: selectedRecord['maxHeartRate'],
                                          avgHeartRate: selectedRecord['averageHeartRate'],
                                        );

                                        Navigator.of(context).pop();
                                        Navigator.of(context).pop();
                                        appState.startTracking(
                                          '나 vs 친구',
                                          opponentId: _selectedFriend!.id.toInt(),
                                          recordId: _selectedRecordId,
                                        );
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF52A486),
                                  disabledBackgroundColor: Colors.grey.shade300,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                child: Text(
                                  '시작하기',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      }
    } catch (e) {
      debugPrint('친구 등산 기록 목록 조회 오류: $e');
      if (context.mounted) {
        Navigator.of(context).pop();
        _showNoRecordsDialog(context);
      }
    }
  }

  String _formatMinutes(num minutes) {
    final int hrs = (minutes / 60).floor();
    final int mins = (minutes % 60).toInt();

    if (hrs > 0) {
      return '${hrs}시간 ${mins}분';
    } else {
      return '${mins}분';
    }
  }

  void _showNoRecordsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: const Text(
                    '등산 기록 없음',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xFFFF5151).withOpacity(0.3), width: 1),
                    borderRadius: BorderRadius.circular(15),
                    color: Color(0xFFFFEFEF),
                  ),
                  child: const Center(
                    child: Text(
                      '해당 산/등산로에 대한\n친구의 등산 기록이 없습니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF52A486),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNotPossibleDialog(BuildContext context, String nickname) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFF3F3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: Color(0xFFFF5151),
                    size: 32,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  '등산 기록 없음',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '$nickname님은 선택하신 곳의\n등산 기록이 없어요!\n다른 친구를 검색해보세요', // Updated text
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF52A486),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '확인',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}