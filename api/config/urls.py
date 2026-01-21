from django.contrib import admin
from django.urls import path

from core.views import health, metrics

urlpatterns = [
    path("admin/", admin.site.urls),
    path("health", health),
    path("metrics", metrics),
]
