var gulp = require('gulp');
var coffee = require('gulp-coffee');

path = 'src/*';

gulp.task('coffee', function(){
    gulp.src([path])
    .pipe(coffee())
    .pipe(gulp.dest('lib'));
});
