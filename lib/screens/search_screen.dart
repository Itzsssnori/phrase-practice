import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import '../models/phrase.dart';
import '../services/mock_data_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_search_bar.dart';
import '../widgets/phrase_card.dart';

/// Full-text search screen for discovering phrases, translations, and notes.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<Phrase> _results = [];
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _results = List.from(MockDataService.samplePhrases);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _hasSearched = query.trim().isNotEmpty;
      if (!_hasSearched) {
        _results = List.from(MockDataService.samplePhrases);
      } else {
        final q = query.toLowerCase();
        _results = MockDataService.samplePhrases.where((phrase) {
          return phrase.originalText.toLowerCase().contains(q) ||
              phrase.translatedText.toLowerCase().contains(q) ||
              (phrase.contextNote?.toLowerCase().contains(q) ?? false);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Phrases'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppSearchBar(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearchChanged,
                onClear: () => _onSearchChanged(''),
              ),
            ),
            Expanded(
              child: _results.isEmpty
                  ? AppEmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No phrases found',
                      message: 'Try searching for different keywords or everyday expressions.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      itemCount: _results.length,
                      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final phrase = _results[index];
                        return PhraseCard(
                          phrase: phrase,
                          onTap: () => context.push('/phrase-study'),
                          onFavoriteToggle: (val) {
                            setState(() {
                              _results[index] = phrase.copyWith(isFavorite: val);
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
