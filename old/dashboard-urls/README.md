# _dashboard-urls_ Content Pack

## Contents

The following represents the folder structure and content that will be imported in to Stroom with this content pack.

* _Dashboard URLs_
    * **AnnotationID XSLT** `Pipeline`

        The  translation to extract annotation ID from a <Record> type XML and add that field to the <Record> type XML.
        This would be expected to vary from pipeline to pipeline, so this one is just an example
    * **AnnotationURL XSLT** `Pipeline`

        The  translation to convert <Record> AnnotationID into a URL and replace the AnnotationID with AnnotationURL.
        This is expected to be reused across pipelines, allowing a central place to maintain the hostname of the annotation service.
    * **DashboardID XSLT** `Pipeline`

        The  translation to extract Dashboard ID from a <Record> type XML and add that field to the <Record> type XML.
        This would be expected to vary from pipeline to pipeline, so this one is just an example
    * **DashboardURL XSLT** `Pipeline`

        The  translation to convert <Record> DashboardID into a URL and replace the DashboardID with DashboardURL.
        This is expected to be reused across pipelines, allowing a central place to maintain the construction of a relative Dashboard URL.

