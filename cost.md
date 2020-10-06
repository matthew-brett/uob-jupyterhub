# Costs

These are notes as of 6 October 2020.

I'm using Google Cloud, in region London (`europe-west2`).

The pricing calculator is <https://cloud.google.com/products/calculator>.

I started with:

* default pool - 2 * `n1-custom-1-6656` (1 CPU each, 6.5GB RAM) - \$77.81,
  effective hourly rate (EHR) \$0.053
* user pool - `e2-standard-2`.

If I upgrade to:

* default pool - 2 * `n1-standard-2` (2 CPU each 7.5GB RAM) - \$125.09, EHR
  \$0.086.
