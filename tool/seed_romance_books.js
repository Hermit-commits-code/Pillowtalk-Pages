#!/usr/bin/env node

/**
 * Seed Spicy Reads with romance books from Google Books API
 *
 * Usage:
 *   node tool/seed_romance_books.js [--dry-run] [--limit=100]
 *
 * Environment Variables:
 *   GOOGLE_BOOKS_API_KEY: Your Google Books API key (optional, has rate limits without it)
 *   FIREBASE_PROJECT_ID: Your Firebase project ID
 *
 * This script:
 * 1. Queries Google Books API for popular romance books
 * 2. Stores them in Firestore under /books collection
 * 3. Marks them with isPreSeeded: true for filtering
 */

const axios = require('axios');
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Configuration
// Set your Google Books API key here or via environment variable GOOGLE_BOOKS_API_KEY
const GOOGLE_BOOKS_API_KEY =
  process.env.GOOGLE_BOOKS_API_KEY || 'AIzaSyDRvL7b4MKYf3JORJSxitoeOOHtcBbJCfo';
const GOOGLE_BOOKS_API_URL = 'https://www.googleapis.com/books/v1/volumes';
const DRY_RUN = process.argv.includes('--dry-run');
const LIMIT = parseInt(
  process.argv.find((arg) => arg.startsWith('--limit='))?.split('=')[1] ||
    '500',
  10,
);

// Romance keywords to search - expanded for diversity
const ROMANCE_QUERIES = [
  'contemporary romance',
  'paranormal romance',
  'historical romance',
  'spicy romance',
  'romantic suspense',
  'fantasy romance',
  // This script was archived and the original has been moved to:
  //   tool/archive_2025-11-12_1200/seed_romance_books.js
  //
  // The file was replaced with this placeholder to reduce clutter in `tool/`.
  // If you need to run the original script, use the archived copy above.

  console.log('This script has been archived. See tool/archive_2025-11-12_1200/');
  'age gap romance',
