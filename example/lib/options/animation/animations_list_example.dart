import 'package:flutter/material.dart';
import 'package:power3d/power3d.dart';

class AnimationsListExample extends StatefulWidget {
  const AnimationsListExample({super.key});

  @override
  State<AnimationsListExample> createState() => _AnimationsListExampleState();
}

class _AnimationsListExampleState extends State<AnimationsListExample> {
  late Power3DController controller;

  @override
  void initState() {
    super.initState();
    controller = Power3DController();
    // Default camera alpha for front view in robot.glb
    //controller.value = controller.value.copyWith(cameraAlpha: 1.57);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animations List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.getAnimationsList(),
            tooltip: 'Fetch Animations',
          ),
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: () => controller.resetScene(),
            tooltip: 'Reset Scene',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.black12,
              child: Power3D(
                controller: controller,
                initialModel: const Power3DData(
                  path: 'assets/robot.glb',
                  source: Power3DSource.asset,
                ),
              ),
            ),
          ),
          ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, state, _) {
              return Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          const Text(
                            'Play Multiple:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Switch(
                            value: state.playMultiple,
                            onChanged: (val) => controller.setPlayMultiple(val),
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start All'),
                            onPressed: () => controller.startAllAnimations(),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.stop),
                            label: const Text('Stop All'),
                            onPressed: () => controller.stopAllAnimations(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    if (state.animations.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Text(
                            'No animations found or not fetched yet.',
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          itemCount: state.animations.length,
                          itemBuilder: (context, index) {
                            final anim = state.animations[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Column(
                                children: [
                                  ListTile(
                                    leading: Icon(
                                      anim.isPlaying
                                          ? Icons.directions_run
                                          : Icons.accessibility,
                                      color: anim.isPlaying
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                    title: Text(
                                      anim.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            anim.isPlaying
                                                ? Icons.pause
                                                : Icons.play_arrow,
                                          ),
                                          onPressed: () {
                                            if (anim.isPlaying) {
                                              controller.pauseAnimation(
                                                anim.name,
                                              );
                                            } else {
                                              controller.playAnimation(
                                                anim.name,
                                                speed: anim.speed,
                                                loop: anim.loop,
                                              );
                                            }
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.stop),
                                          onPressed: () => controller
                                              .stopAnimation(anim.name),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      children: [
                                        const Text('Speed: '),
                                        Expanded(
                                          child: Slider(
                                            value: anim.speed,
                                            min: 0.1,
                                            max: 5.0,
                                            onChanged: (val) =>
                                                controller.setAnimationSpeed(
                                                  anim.name,
                                                  val,
                                                ),
                                          ),
                                        ),
                                        Text(
                                          '${anim.speed.toStringAsFixed(1)}x',
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 16,
                                      right: 16,
                                      bottom: 8,
                                    ),
                                    child: Row(
                                      children: [
                                        const Text('Pause After: '),
                                        TextButton(
                                          onPressed: () =>
                                              controller.pauseAfter(
                                                anim.name,
                                                const Duration(seconds: 2),
                                              ),
                                          child: const Text('2s'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              controller.pauseAfter(
                                                anim.name,
                                                const Duration(seconds: 5),
                                              ),
                                          child: const Text('5s'),
                                        ),
                                        const Spacer(),
                                        const Text('Loop: '),
                                        Checkbox(
                                          value: anim.loop,
                                          onChanged: (val) {
                                            if (val != null) {
                                              controller.setAnimationLoop(
                                                anim.name,
                                                val,
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
