import 'package:blog_app/features/blog/data/models/blog_model.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

abstract interface class BlogLocalDataSource {
  void uploadLocalBlogs({required List<BlogModel> blogs});
  List<BlogModel> loadBlogs();
}

class BlogLocalDataSourceImpl implements BlogLocalDataSource {
  final Box box;
  BlogLocalDataSourceImpl(this.box);

  @override
  List<BlogModel> loadBlogs() {
    debugPrint("loadBlogs CALLED FROM LOAD");
    debugPrint("Hive Raw Map: ${box.toMap()}");
    List<BlogModel> blogs = [];
    for (int i = 0; i < box.length; i++) {
      final raw = box.get(i.toString());
      if (raw != null) {
        // assume raw is a Map<String, dynamic> produced by BlogModel.toJson()
        blogs.add(BlogModel.fromJson(Map<String, dynamic>.from(raw)));
      }
    }

    return blogs;
  }

  @override
  void uploadLocalBlogs({required List<BlogModel> blogs}) {
    box.clear();

    debugPrint("loadBlogs CALLED FROM UPLOAD");
    debugPrint("Hive Raw Map: ${box.toMap()}");

    for (int i = 0; i < blogs.length; i++) {
      box.put(i.toString(), blogs[i].toJson());
    }
  }
}
