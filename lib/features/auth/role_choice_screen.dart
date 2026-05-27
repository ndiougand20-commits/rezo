part of 'auth_flow.dart';

class RoleChoiceScreen extends StatefulWidget {
  const RoleChoiceScreen({super.key});

  @override
  State<RoleChoiceScreen> createState() => _RoleChoiceScreenState();
}

class _RoleChoiceScreenState extends State<RoleChoiceScreen> {
  UserRole _selectedRole = UserRole.etudiant;

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Choisis ton profil',
      subtitle: 'Selectionne ton role pour personnaliser ton experience.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  Theme.of(context).colorScheme.primaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: const Color(0xFFDCDCDC)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFD4D4D4)),
                  ),
                  child: Icon(_selectedRole.icon, color: Colors.black),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Profil selectionne',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedRole.label,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.auto_awesome_rounded, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Je suis...',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: UserRole.values
                .map(
                  (role) => _RoleChoiceTile(
                    role: role,
                    selected: role == _selectedRole,
                    onTap: () => setState(() => _selectedRole = role),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: KeyedSubtree(
              key: ValueKey(_selectedRole),
              child: _RoleBenefitCard(
                role: _selectedRole,
              ),
            ),
          ),
          const SizedBox(height: 26),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushReplacementNamed(
                AppRoutes.welcome,
                arguments: _selectedRole,
              );
            },
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Continuer'),
          ),
          const SizedBox(height: 8),
          Text(
            'Tu pourras toujours modifier ton profil ensuite.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleChoiceTile extends StatelessWidget {
  const _RoleChoiceTile({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final UserRole role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 118,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF111111) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? const Color(0xFF111111) : const Color(0xFFD8D8D8),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  role.icon,
                  size: 22,
                  color: selected ? Colors.white : Colors.black,
                ),
                const SizedBox(height: 8),
                Text(
                  role.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
