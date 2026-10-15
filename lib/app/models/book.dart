import 'package:flutter/material.dart';

class Book {
  final String title;
  final String author;
  final int borrowCount;
  final Color color;
  const Book(this.title, this.author, this.borrowCount, this.color);
} 