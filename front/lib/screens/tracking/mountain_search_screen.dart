// mountain_search_screen.dart: 산 검색 기능 제공 화면
// - 산 이름 검색 기능 제공
// - 검색 결과 목록 표시
// - 산 선택 시 등산로 선택 화면으로 이동

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';

class MountainSearchScreen extends StatefulWidget {
  const MountainSearchScreen({super.key});

  @override
  State<MountainSearchScreen> createState() => _MountainSearchScreenState();
}

class _MountainSearchScreenState extends State<MountainSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _mountainList = [];
  List<String> _filteredList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMountainData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 산 데이터 로드 (서버에서 데이터를 가져오는 로직 추가 필요)
  void _loadMountainData() {
    setState(() {
      _isLoading = true;
    });

    // 임시 데이터 - 실제로는 API 호출로 대체
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _mountainList.addAll([
          '설악산',
          '북한산',
          '지리산',
          '한라산',
          '덕유산',
          '소백산',
          '오대산',
          '치악산',
          '월출산',
          '속리산',
          '계룡산',
          '내장산',
          '가야산',
          '주왕산',
          '불굴산'
        ]);
        _filteredList = List.from(_mountainList);
        _isLoading = false;
      });
    });
  }

  // 검색어에 따라 목록 필터링
  void _filterMountainList(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredList = List.from(_mountainList);
      } else {
        _filteredList = _mountainList
            .where((mountain) => mountain.contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '산 검색',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // 검색 필드
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '산 이름을 입력하세요',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: _filterMountainList,
          ),
          const SizedBox(height: 16),

          // 결과 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredList.isEmpty
                    ? const Center(child: Text('검색 결과가 없습니다.'))
                    : ListView.builder(
                        itemCount: _filteredList.length,
                        itemBuilder: (context, index) {
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(_filteredList[index]),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                // 산 선택 시 AppState 업데이트
                                Provider.of<AppState>(context, listen: false)
                                    .selectMountain(_filteredList[index]);
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
