import 'package:fitness_care_bagerhat/app/router/routes.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_empty_state.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_error_state.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_shimmer.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_text_field.dart';
import 'package:fitness_care_bagerhat/features/admin/members/list/members_controller.dart';
import 'package:fitness_care_bagerhat/features/admin/members/list/widgets/member_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// ## MembersListScreen
///
/// Admin view showing a searchable, filterable, paginated list of all gym members.
class MembersListScreen extends ConsumerStatefulWidget {
  const MembersListScreen({super.key});

  @override
  ConsumerState<MembersListScreen> createState() => _MembersListScreenState();
}

class _MembersListScreenState extends ConsumerState<MembersListScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(membersControllerProvider.notifier).load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(membersControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Members'),
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.userPlus()),
            onPressed: () => context.push(Routes.adminMemberCreate),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: AppSpacing.paddingAll16,
            child: Column(
              children: [
                GymTextField(
                  hint: 'Search by name or phone...',
                  prefixIcon: Icon(PhosphorIcons.magnifyingGlass()),
                  onChanged:
                      ref.read(membersControllerProvider.notifier).search,
                ),
                const SizedBox(height: AppSpacing.s12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        isSelected: state.statusFilter == 'all',
                        onTap: () => ref
                            .read(membersControllerProvider.notifier)
                            .setFilter('all'),
                      ),
                      _FilterChip(
                        label: 'Active',
                        isSelected: state.statusFilter == 'active',
                        onTap: () => ref
                            .read(membersControllerProvider.notifier)
                            .setFilter('active'),
                      ),
                      _FilterChip(
                        label: 'Expiring',
                        isSelected: state.statusFilter == 'expiring',
                        onTap: () => ref
                            .read(membersControllerProvider.notifier)
                            .setFilter('expiring'),
                      ),
                      _FilterChip(
                        label: 'Inactive',
                        isSelected: state.statusFilter == 'inactive',
                        onTap: () => ref
                            .read(membersControllerProvider.notifier)
                            .setFilter('inactive'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _buildList(state),
          ),
        ],
      ),
    );
  }

  Widget _buildList(MembersState state) {
    if (state.isLoading) {
      return ListView.separated(
        padding: AppSpacing.paddingAll16,
        itemCount: 10,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s12),
        itemBuilder: (_, __) => const GymShimmer.card(height: 80),
      );
    }

    if (state.error != null) {
      return GymErrorState(
        message: state.error!.message,
        onRetry: () =>
            ref.read(membersControllerProvider.notifier).load(refresh: true),
      );
    }

    if (state.members.isEmpty) {
      return GymEmptyState(
        message: state.searchQuery.isEmpty
            ? 'No members found. Add your first member!'
            : 'No members match your search.',
        animationPath: 'assets/animations/empty_members.json', // Placeholder
        actionLabel: state.searchQuery.isEmpty ? 'Add Member' : null,
        onAction: state.searchQuery.isEmpty
            ? () => context.push(Routes.adminMemberCreate)
            : null,
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(membersControllerProvider.notifier).load(refresh: true),
      child: ListView.separated(
        controller: _scrollController,
        padding: AppSpacing.paddingAll16,
        itemCount: state.members.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s12),
        itemBuilder: (context, index) {
          if (index == state.members.length) {
            return const Center(
              child: Padding(
                padding: AppSpacing.paddingAll16,
                child: CircularProgressIndicator(),
              ),
            );
          }

          final member = state.members[index];
          return MemberListTile(
            member: member,
            onTap: () => context.push(Routes.adminMemberDetail(member.id)),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.s8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
