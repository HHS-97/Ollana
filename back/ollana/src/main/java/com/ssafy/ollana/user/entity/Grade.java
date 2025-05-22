package com.ssafy.ollana.user.entity;

public enum Grade {
    SEED(0),
    SPROUT(100),
    TREE(300),
    FRUIT(500),
    MOUNTAIN(800);

    // 다음 grade로 가기 위한 요구 경험치
    private final int requiredExp;

    // 최대 경험치
    private static final int MAX_EXP = 1000;

    Grade(int requiredExp) {
        this.requiredExp = requiredExp;
    }

    public int getRequiredExp() {
        return this.requiredExp;
    }

    public static int getMaxExp() {
        return MAX_EXP;
    }

    // 경험치에 따른 grade 반환
    public static Grade getGrade(int exp) {
        Grade userGrade = SEED;

        for (Grade grade : values()) {
            if (exp >= grade.getRequiredExp()) {
                userGrade = grade;
            } else {
                break;
            }
        }

        return userGrade;
    }
}
