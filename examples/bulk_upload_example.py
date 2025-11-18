#!/usr/bin/env python3
"""
Bulk Image Upload Example for StyleFinder

This script demonstrates how to:
1. Upload multiple clothing images for bulk processing
2. Poll job status until completion
3. Retrieve and display results

Usage:
    python3 bulk_upload_example.py --images ./closet_photos/*.jpg
"""

import requests
import time
import argparse
from pathlib import Path
from typing import List
import sys

# =============================================================================
# Configuration - UPDATE THESE VALUES
# =============================================================================

DAYTONA_URL = "https://8000-xxxxx.daytona.app"  # Your Daytona URL
USER_ID = "test-user-123"  # Your user ID
REMOVE_BACKGROUND = True  # Remove background from images

# =============================================================================


class BulkUploader:
    """Handle bulk image uploads to StyleFinder"""

    def __init__(self, base_url: str, user_id: str):
        self.base_url = base_url.rstrip('/')
        self.user_id = user_id

    def upload_images(self, image_paths: List[Path], remove_background: bool = True) -> dict:
        """
        Upload multiple images for bulk processing.

        Args:
            image_paths: List of image file paths
            remove_background: Whether to remove background

        Returns:
            Response dict with job_id
        """
        print(f"📦 Preparing to upload {len(image_paths)} images...")

        # Prepare multipart form data
        files = []
        for img_path in image_paths:
            if not img_path.exists():
                print(f"⚠️  Warning: {img_path} not found, skipping")
                continue

            files.append(
                ('files', (img_path.name, open(img_path, 'rb'), 'image/jpeg'))
            )

        if not files:
            raise ValueError("No valid image files found")

        try:
            # Send request
            print(f"⬆️  Uploading to {self.base_url}...")
            response = requests.post(
                f"{self.base_url}/bulk-analyze",
                files=files,
                data={
                    'user_id': self.user_id,
                    'remove_background': str(remove_background).lower()
                },
                timeout=60
            )

            response.raise_for_status()
            result = response.json()

            print(f"✅ Upload successful!")
            print(f"   Job ID: {result['job_id']}")
            print(f"   Images: {result['total_images']}")

            return result

        finally:
            # Close all file handles
            for _, (_, f, _) in files:
                f.close()

    def check_status(self, job_id: str) -> dict:
        """
        Check the status of a processing job.

        Args:
            job_id: Job identifier

        Returns:
            Status dict
        """
        response = requests.get(f"{self.base_url}/bulk-status/{job_id}")
        response.raise_for_status()
        return response.json()

    def get_results(self, job_id: str) -> dict:
        """
        Get results from a completed job.

        Args:
            job_id: Job identifier

        Returns:
            Results dict with analyzed items
        """
        response = requests.get(f"{self.base_url}/bulk-results/{job_id}")
        response.raise_for_status()
        return response.json()

    def poll_until_complete(self, job_id: str, poll_interval: int = 5) -> dict:
        """
        Poll job status until completion.

        Args:
            job_id: Job identifier
            poll_interval: Seconds between status checks

        Returns:
            Final status dict
        """
        print(f"\n📊 Monitoring job progress...")
        print(f"   (Polling every {poll_interval} seconds)")

        start_time = time.time()

        while True:
            status = self.check_status(job_id)

            processed = status['processed_images']
            failed = status['failed_images']
            total = status['total_images']
            progress = status['progress_percent']
            state = status['status']

            # Display progress
            elapsed = int(time.time() - start_time)
            bar_length = 30
            filled = int(bar_length * progress / 100)
            bar = '█' * filled + '░' * (bar_length - filled)

            print(f"\r   [{bar}] {progress:.1f}% | {processed}/{total} | {elapsed}s elapsed", end='', flush=True)

            # Check if done
            if state == 'completed':
                print(f"\n✅ Processing complete!")
                print(f"   Processed: {processed} items")
                if failed > 0:
                    print(f"   Failed: {failed} items")
                print(f"   Time: {elapsed}s")
                break
            elif state == 'failed':
                print(f"\n❌ Job failed: {status.get('error_message', 'Unknown error')}")
                break

            time.sleep(poll_interval)

        return status


def display_results(results: dict):
    """Display processing results in a readable format"""

    print(f"\n🎉 Results for Job {results['job_id']}")
    print(f"   Status: {results['status']}")
    print(f"   Total Items: {results['total_items']}\n")

    if results['total_items'] == 0:
        print("   No items processed.")
        return

    print("📋 Analyzed Items:")
    print("─" * 80)

    for i, item_data in enumerate(results['items'], 1):
        status = item_data['status']
        item = item_data.get('item')

        if status == 'completed' and item:
            print(f"\n{i}. {item['type'].upper()}")
            print(f"   Color:      {item['color']}")
            print(f"   Pattern:    {item['pattern']}")
            print(f"   Style:      {item['style']}")
            print(f"   Confidence: {item['confidence']:.0%}")
            print(f"   Seasons:    {', '.join(item['season'])}")
            print(f"   Pairs with: {', '.join(item['pairs_well_with'][:3])}")
            if item.get('material'):
                print(f"   Material:   {item['material']}")
            if item.get('extracted_image_url'):
                print(f"   Image:      {item['extracted_image_url'][:50]}...")
        else:
            print(f"\n{i}. FAILED")
            print(f"   Error: {item_data.get('error_message', 'Unknown error')}")

    print("\n" + "─" * 80)


def main():
    """Main entry point"""

    parser = argparse.ArgumentParser(
        description="Bulk upload clothing images to StyleFinder"
    )
    parser.add_argument(
        '--images',
        nargs='+',
        required=True,
        help='Image files to upload (e.g., ./images/*.jpg)'
    )
    parser.add_argument(
        '--url',
        default=DAYTONA_URL,
        help=f'Daytona URL (default: {DAYTONA_URL})'
    )
    parser.add_argument(
        '--user-id',
        default=USER_ID,
        help=f'User ID (default: {USER_ID})'
    )
    parser.add_argument(
        '--no-background-removal',
        action='store_true',
        help='Skip background removal'
    )
    parser.add_argument(
        '--poll-interval',
        type=int,
        default=5,
        help='Status poll interval in seconds (default: 5)'
    )

    args = parser.parse_args()

    # Convert image paths
    image_paths = [Path(img) for img in args.images]

    # Validate
    if not image_paths:
        print("❌ Error: No images specified")
        sys.exit(1)

    if not args.url or args.url == "https://8000-xxxxx.daytona.app":
        print("❌ Error: Please update DAYTONA_URL in the script or use --url")
        sys.exit(1)

    print("=" * 80)
    print("🚀 StyleFinder Bulk Image Upload")
    print("=" * 80)
    print(f"   Server:     {args.url}")
    print(f"   User ID:    {args.user_id}")
    print(f"   Images:     {len(image_paths)}")
    print(f"   Background: {'Removed' if not args.no_background_removal else 'Original'}")
    print("=" * 80)

    # Create uploader
    uploader = BulkUploader(args.url, args.user_id)

    try:
        # Step 1: Upload
        result = uploader.upload_images(
            image_paths,
            remove_background=not args.no_background_removal
        )
        job_id = result['job_id']

        # Step 2: Poll status
        final_status = uploader.poll_until_complete(job_id, args.poll_interval)

        # Step 3: Get results
        if final_status['status'] == 'completed':
            results = uploader.get_results(job_id)
            display_results(results)

            # Save results to file
            import json
            output_file = f"results_{job_id}.json"
            with open(output_file, 'w') as f:
                json.dump(results, f, indent=2)
            print(f"\n💾 Full results saved to: {output_file}")

        print("\n✨ Done!")

    except requests.exceptions.RequestException as e:
        print(f"\n❌ Network error: {e}")
        sys.exit(1)
    except KeyboardInterrupt:
        print("\n\n⏸️  Interrupted by user")
        print("   Note: Processing continues in background!")
        sys.exit(0)
    except Exception as e:
        print(f"\n❌ Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
