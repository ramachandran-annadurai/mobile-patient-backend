"""
Setup script for Medication OCR API Package
"""

from setuptools import setup, find_packages
import os

# Read the README file for long description
def read_readme():
    with open("README.md", "r", encoding="utf-8") as fh:
        return fh.read()

# Read requirements.txt for dependencies
def read_requirements():
    with open("requirements.txt", "r", encoding="utf-8") as fh:
        return [line.strip() for line in fh if line.strip() and not line.startswith("#")]

setup(
    name="medication-ocr-api",
    version="1.0.0",
    author="LogicalMinds",
    author_email="info@logicalminds.com",
    description="A comprehensive OCR API for processing medication-related documents",
    long_description=read_readme(),
    long_description_content_type="text/markdown",
    url="https://github.com/logicalminds/medication-ocr-api",
    packages=find_packages(),
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "Intended Audience :: Healthcare Industry",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Topic :: Scientific/Engineering :: Artificial Intelligence",
        "Topic :: Software Development :: Libraries :: Python Modules",
        "Topic :: Text Processing :: Linguistic",
    ],
    python_requires=">=3.8",
    install_requires=read_requirements(),
    extras_require={
        "dev": [
            "pytest>=6.0",
            "pytest-asyncio>=0.18.0",
            "black>=21.0",
            "flake8>=3.8",
            "mypy>=0.800",
        ],
        "docs": [
            "sphinx>=4.0",
            "sphinx-rtd-theme>=1.0",
        ],
    },
    entry_points={
        "console_scripts": [
            "medication-ocr-api=medication.app.main:main",
        ],
    },
    include_package_data=True,
    package_data={
        "medication": [
            "webhook_configs.json",
            "*.md",
            "*.txt",
        ],
    },
    keywords="ocr, medication, prescription, medical, document, text-extraction, api",
    project_urls={
        "Bug Reports": "https://github.com/logicalminds/medication-ocr-api/issues",
        "Source": "https://github.com/logicalminds/medication-ocr-api",
        "Documentation": "https://medication-ocr-api.readthedocs.io/",
    },
)
