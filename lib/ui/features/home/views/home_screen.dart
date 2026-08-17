import 'package:fitness/ui/core/di.dart' as di;
import 'package:fitness/ui/core/theme/app_pallet.dart';
import 'package:fitness/ui/features/chat/views/agent_chat_page.dart';
import 'package:fitness/ui/features/fitness/views/home_page.dart';
import 'package:fitness/ui/features/fitness/view_models/fitness_view_model.dart';
import 'package:fitness/ui/features/home/views/custom_bottom_bar.dart';
import 'package:fitness/ui/features/profile/views/profile_page.dart';
import 'package:fitness/ui/features/analytic/views/statistics_page.dart';
import 'package:fitness/data/services/billing/access_policy.dart';
import 'package:fitness/domain/models/premium_feature.dart';
import 'package:fitness/ui/core/widgets/premium_gate.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;
  late final List<Widget> _pages;

  // Chat is index 1 — hide nav bar so the full screen is available
  bool get _hideNav => currentIndex == 1;

  @override
  void initState() {
    super.initState();
    // IndexedStack keeps all pages alive so AgentChatPage's VM is never
    // disposed mid-flight when the user switches tabs.
    _pages = [
      ChangeNotifierProvider(
        create: (_) => di.sl<FitnessViewModel>(),
        child: const FitnessHomePage(),
      ),
      AgentChatPage(onBack: () => setState(() => currentIndex = 0)),
      const StatisticsPage(),
      const ProfilePage(),
    ];
  }

  /// The coach tab is gated. Intercepting here rather than inside
  /// AgentChatPage keeps the tab visible and selectable — the user sees the
  /// paywall for the thing they tapped, and the tab bar does not change shape
  /// when a trial lapses.
  void _onTabTapped(int index) {
    const coachTab = 1;
    if (index == coachTab &&
        !di.sl<AccessPolicy>().canUse(PremiumFeature.agentChat)) {
      requirePremium(context, PremiumFeature.agentChat,
          () => setState(() => currentIndex = coachTab));
      return;
    }
    setState(() => currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalete.backgroundColorBk,
      body: Stack(
        children: [
          // IndexedStack keeps every page mounted so VMs aren't torn down
          IndexedStack(index: currentIndex, children: _pages),

          if (!_hideNav)
            Positioned(
              bottom: 0,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: CustomBottombar(
                  onItemTapped: _onTabTapped,
                  currentIndex: currentIndex,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
