resource "aws_s3_bucket" "this" {
  bucket = "${local.prefix}-storage-${data.aws_caller_identity.current.account_id}"

  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "default_file" {
  bucket  = aws_s3_bucket.this.id
  key     = "default.txt"
  content = <<-EOT
  Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aliquam commodo vestibulum nibh eget interdum. Ut dictum, tortor vel hendrerit imperdiet, turpis eros lacinia dolor, non hendrerit magna dui eget lectus. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Donec malesuada nisl at semper bibendum. Nam lobortis arcu quis leo maximus ultrices. Phasellus molestie, lectus ac gravida vestibulum, urna dui tristique purus, et sollicitudin urna nibh sed urna. Vivamus quis libero non urna laoreet ultrices. Praesent sem tortor, pulvinar at aliquet vitae, mollis nec mi. Nam lobortis fermentum erat vel posuere. Etiam id nisl ut nunc pellentesque tempor.

  Curabitur maximus tortor non tellus rutrum efficitur. Nam finibus aliquam pharetra. Nulla quis magna consequat, lacinia est non, elementum lorem. Quisque vitae interdum felis. Vivamus luctus pharetra ex at posuere. Vestibulum sodales sem placerat pharetra consectetur. Vivamus accumsan lectus nec porta dictum. Sed vitae nunc molestie, dapibus nisl pellentesque, efficitur ex. Sed viverra egestas augue, a facilisis turpis sollicitudin vitae. Integer congue, nulla et ultrices imperdiet, risus leo cursus tellus, id scelerisque ligula urna a metus. Nulla vitae feugiat est, lacinia egestas ligula. Duis sed elit nec libero efficitur elementum sit amet et metus.

  Nullam accumsan, dui iaculis viverra elementum, metus mi mattis tellus, sit amet accumsan orci magna ac felis. Proin hendrerit diam lacus, vitae ultrices justo dignissim accumsan. Mauris at mauris magna. Sed tincidunt ultricies elit eu pellentesque. Maecenas lacinia lectus vitae pulvinar finibus. Praesent lobortis mollis augue nec dapibus. Ut ultricies lobortis ipsum ut porttitor.

  Ut interdum eu massa et auctor. Cras ullamcorper magna tortor, sed accumsan sapien interdum eu. Sed egestas lacus eget libero sagittis iaculis. Morbi fringilla velit erat. Nam elementum egestas purus, eu convallis arcu volutpat quis. Donec pellentesque ipsum sit amet urna cursus, sit amet finibus justo vulputate. Ut luctus sapien in fermentum feugiat. Nulla convallis arcu eget elementum viverra. Etiam sodales sapien vitae erat tempus, lobortis venenatis felis tempor. Curabitur ipsum urna, auctor ut eleifend a, tristique ac magna. Suspendisse potenti.

  Praesent eu tortor non risus blandit consequat. Curabitur eget fermentum ante. In non mollis lectus, sed scelerisque lorem. Fusce quis risus at nibh lobortis sollicitudin. Cras tellus enim, ultricies et nunc eget, feugiat interdum sapien. Etiam malesuada, augue vitae accumsan porttitor, metus dolor volutpat metus, ultrices pulvinar eros sapien id turpis. Vivamus luctus volutpat vulputate. Integer eros tortor, bibendum vitae dui ut, varius dignissim massa. Mauris bibendum mollis posuere. Duis nibh purus, iaculis id consectetur ut, maximus dignissim lacus. Sed molestie nisl vel urna faucibus fringilla. Ut egestas efficitur lectus tempor mollis. Nullam imperdiet convallis mi et accumsan. Mauris malesuada arcu quis quam tempor bibendum. Suspendisse odio nulla, elementum eget finibus sed, fermentum sed dui.
  EOT

  depends_on = [aws_s3_bucket.this]
}
