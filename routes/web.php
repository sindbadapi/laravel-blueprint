<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    $d = 1;

    return view('welcome');
});
