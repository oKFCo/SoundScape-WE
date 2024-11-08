import 'package:flutter/material.dart';
import 'package:SoundScape/models/link_model.dart';

import 'dart:math';

class TracksList extends StatelessWidget {
  final List<Link> addedTracks;
  final Function(int) onRemoveTrack;
  final bool isLoading;

  const TracksList({
    super.key,
    required this.addedTracks,
    required this.onRemoveTrack,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.7),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 4,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            )
          : addedTracks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'No tracks linked.',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (Random().nextInt(100) == 0)
                        Image.asset(
                          'assets/Empty-Cat.png',
                          width: 200,
                          height: 200,
                        ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: addedTracks.length,
                  itemBuilder: (context, index) {
                    final track = addedTracks[index];

                    ImageProvider? imageProvider;
                    final decodedImage = MemoryImage(track.image);
                    imageProvider = decodedImage;

                    return Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 70),
                        child: ListTile(
                          contentPadding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 0),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image(
                              image: imageProvider,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(
                            track.title,
                            style: const TextStyle(
                              color: Color.fromARGB(255, 58, 203, 104),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            track.artist,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            color: Colors.red,
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Confirm Deletion'),
                                  content: const Text(
                                      'Are you sure you want to delete this track?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        onRemoveTrack(index);
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('Delete',
                                          style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
